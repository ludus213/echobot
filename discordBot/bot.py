import os
import asyncio
import math
import httpx
import discord
from discord import app_commands

MIDDLEMAN_URL = os.environ.get("MIDDLEMAN_URL", "http://127.0.0.1:8000")
ADMIN_TOKEN = os.environ.get("MM_ADMIN_TOKEN", "changeme")
DISCORD_TOKEN = os.environ.get("DISCORD_TOKEN", "")
GUILD_ID = os.environ.get("DISCORD_GUILD_ID")

intents = discord.Intents.default()
client = discord.Client(intents=intents)
tree = app_commands.CommandTree(client)


def h():
    return {"X-Admin-Token": ADMIN_TOKEN}


async def fetch_json(method: str, path: str, json=None, params=None):
    url = f"{MIDDLEMAN_URL}{path}"
    async with httpx.AsyncClient(timeout=20) as session:
        r = await session.request(method, url, headers=h(), json=json, params=params)
        r.raise_for_status()
        return r.json()


async def paginate(interaction: discord.Interaction, title: str, rows, render_row, per_page=10):
    pages = max(1, math.ceil(len(rows) / per_page))
    page = 0
    while True:
        start = page * per_page
        end = start + per_page
        chunk = rows[start:end]
        embed = discord.Embed(title=title)
        for row in chunk:
            name, value = render_row(row)
            embed.add_field(name=name, value=value, inline=False)
        embed.set_footer(text=f"Page {page+1}/{pages}")
        if page == 0:
            await interaction.followup.send(embed=embed)
        else:
            await interaction.followup.send(embed=embed, ephemeral=True)
        if pages <= 1:
            break
        page += 1
        if page >= pages:
            break


@tree.command(name="restore", description="Add vestige to a player")
@app_commands.describe(player="Player name", amount="Amount to add")
async def restore(interaction: discord.Interaction, player: str, amount: int):
    await interaction.response.defer(ephemeral=True)
    await fetch_json("POST", "/command/restore", {"player": player, "amount": amount})
    await fetch_json("POST", "/mod/action", {"action": "restore", "player": player, "reason": f"+{amount}"})
    await interaction.followup.send(embed=discord.Embed(title="Restore queued", description=f"{player} +{amount}"))


@tree.command(name="ban", description="Ban a player")
@app_commands.describe(player="Player name")
async def ban(interaction: discord.Interaction, player: str):
    await interaction.response.defer(ephemeral=True)
    await fetch_json("POST", "/command/ban", {"player": player})
    await fetch_json("POST", "/mod/action", {"action": "ban", "player": player})
    await interaction.followup.send(embed=discord.Embed(title="Ban queued", description=player))


@tree.command(name="unban", description="Unban a player")
@app_commands.describe(player="Player name")
async def unban(interaction: discord.Interaction, player: str):
    await interaction.response.defer(ephemeral=True)
    await fetch_json("POST", "/command/unban", {"player": player})
    await fetch_json("POST", "/mod/action", {"action": "unban", "player": player})
    await interaction.followup.send(embed=discord.Embed(title="Unban queued", description=player))


@tree.command(name="strike", description="Add a strike to a player")
@app_commands.describe(player="Player name")
async def strike(interaction: discord.Interaction, player: str):
    await interaction.response.defer(ephemeral=True)
    await fetch_json("POST", "/command/strike", {"player": player})
    await fetch_json("POST", "/mod/action", {"action": "strike", "player": player})
    await interaction.followup.send(embed=discord.Embed(title="Strike queued", description=player))


@tree.command(name="kick", description="Kick a player")
@app_commands.describe(player="Player name")
async def kick(interaction: discord.Interaction, player: str):
    await interaction.response.defer(ephemeral=True)
    await fetch_json("POST", "/command/kick", {"player": player})
    await fetch_json("POST", "/mod/action", {"action": "kick", "player": player})
    await interaction.followup.send(embed=discord.Embed(title="Kick queued", description=player))


@tree.command(name="viewmodlogs", description="View moderation actions")
async def viewmodlogs(interaction: discord.Interaction):
    await interaction.response.defer(ephemeral=True)
    data = await fetch_json("GET", "/mod/actions", params={"offset": 0, "limit": 100})
    rows = data.get("results", [])
    async def render(row):
        return f"{row['action']} {row['player']}", row.get("time", "")
    await paginate(interaction, "Mod Actions", rows, lambda r: (f"{r['action']} {r['player']}", r.get("time", "")))


@tree.command(name="getdeathlogs", description="View death logs")
async def getdeathlogs(interaction: discord.Interaction):
    await interaction.response.defer(ephemeral=True)
    data = await fetch_json("GET", "/deaths", params={"offset": 0, "limit": 100})
    rows = data.get("results", [])
    await paginate(interaction, "Death Logs", rows, lambda r: (f"{r['victim']}", f"{r.get('time','')} {r.get('cause','')} {r.get('attacker','') or ''}"))


@tree.command(name="viewdeathlogsofplayer", description="View death logs of a player")
@app_commands.describe(player="Player name")
async def viewdeathlogsofplayer(interaction: discord.Interaction, player: str):
    await interaction.response.defer(ephemeral=True)
    data = await fetch_json("GET", f"/deaths/player/{player}", params={"offset": 0, "limit": 100})
    rows = data.get("results", [])
    await paginate(interaction, f"Death Logs {player}", rows, lambda r: (f"{r['victim']}", f"{r.get('time','')} {r.get('cause','')} {r.get('attacker','') or ''}"))


@tree.command(name="viewdeathinstance", description="View a death instance")
@app_commands.describe(instanceid="Death instance id")
async def viewdeathinstance(interaction: discord.Interaction, instanceid: str):
    await interaction.response.defer(ephemeral=True)
    data = await fetch_json("GET", f"/deaths/instance/{instanceid}")
    r = data.get("result")
    embed = discord.Embed(title="Death Instance")
    for k in ["instance_id", "victim", "attacker", "cause", "time"]:
        embed.add_field(name=k, value=str(r.get(k)), inline=False)
    await interaction.followup.send(embed=embed)


@tree.command(name="seestrikes", description="See strikes for a player")
@app_commands.describe(player="Player name")
async def seestrikes(interaction: discord.Interaction, player: str):
    await interaction.response.defer(ephemeral=True)
    data = await fetch_json("GET", "/player/state", params={"player": player})
    r = data.get("result") or {}
    strikes = r.get("strikes", 0)
    banned = bool(r.get("banned", 0))
    embed = discord.Embed(title="Player State")
    embed.add_field(name="player", value=player, inline=False)
    embed.add_field(name="strikes", value=str(strikes), inline=False)
    embed.add_field(name="banned", value=str(banned), inline=False)
    await interaction.followup.send(embed=embed)


@client.event
async def on_ready():
    if GUILD_ID:
        guild = discord.Object(id=int(GUILD_ID))
        await tree.sync(guild=guild)
    else:
        await tree.sync()


if __name__ == "__main__":
    if not DISCORD_TOKEN:
        raise SystemExit("DISCORD_TOKEN not set")
    client.run(DISCORD_TOKEN)