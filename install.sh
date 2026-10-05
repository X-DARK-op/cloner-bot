#!/usr/bin/env bash
set -e

APP_DIR="/opt/blood-cloud-cloner"

clear

# ============================================================
# BLOOD CLOUD SERVER CLONER
# ============================================================

printf '\033[1;31m'

cat <<'EOF'

██████╗ ██╗      ██████╗  ██████╗ ██████╗
██╔══██╗██║     ██╔═══██╗██╔═══██╗██╔══██╗
██████╔╝██║     ██║   ██║██║   ██║██║  ██║
██╔══██╗██║     ██║   ██║██║   ██║██║  ██║
██████╔╝███████╗╚██████╔╝╚██████╔╝██████╔╝
╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝

██████╗██╗      ██████╗ ██╗   ██╗██████╗
██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
██║     ██║     ██║   ██║██║   ██║██║  ██║
██║     ██║     ██║   ██║██║   ██║██║  ██║
╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
 ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝

        ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗
        ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗
        ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝
        ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗
        ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║
        ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝

                    S E R V E R   C L O N E R

EOF

printf '\033[0m'

echo
echo -e "\033[1;31m============================================================\033[0m"
echo -e "\033[1;37m             BLOOD CLOUD SERVER CLONER\033[0m"
echo -e "\033[1;31m============================================================\033[0m"
echo

# ============================================================
# ROOT CHECK
# ============================================================

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# ============================================================
# INSTALL DEPENDENCIES
# ============================================================

echo "[+] Updating packages..."

apt-get update -y

echo "[+] Installing Python..."

apt-get install -y python3 python3-venv python3-pip

mkdir -p "$APP_DIR"
cd "$APP_DIR"

echo "[+] Creating virtual environment..."

python3 -m venv venv

source "$APP_DIR/venv/bin/activate"

echo "[+] Installing Discord.py..."

pip install --upgrade pip
pip install -U discord.py python-dotenv

# ============================================================
# TOKEN
# ============================================================

echo
echo -e "\033[1;31m============================================================\033[0m"
echo -e "\033[1;37m                    BOT TOKEN\033[0m"
echo -e "\033[1;31m============================================================\033[0m"
echo
echo "Enter your Discord Bot Token."
echo
echo "Example:"
echo "MTAxMjM0NTY3ODkwNTY3ODkw.GAbCdE.xxxxxxxxxxxxxxxxx"
echo

read -r -s -p "Enter Token: " TOKEN

echo

if [ -z "$TOKEN" ]; then
    echo "[!] Token empty hai."
    exit 1
fi

cat > "$APP_DIR/.env" <<EOF
DISCORD_TOKEN=$TOKEN
EOF

chmod 600 "$APP_DIR/.env"

unset TOKEN

# ============================================================
# CREATE BOT
# ============================================================

echo
echo "[+] Creating bot.py..."

cat > "$APP_DIR/bot.py" <<'PY'
import os
import asyncio
import discord
from dotenv import load_dotenv

load_dotenv()

TOKEN = os.getenv("DISCORD_TOKEN")

if not TOKEN:
    raise RuntimeError("DISCORD_TOKEN missing hai.")

intents = discord.Intents.default()
intents.guilds = True

client = discord.Client(intents=intents)


def ask(question):
    while True:
        value = input(f"{question} [Y/N]: ").strip().lower()

        if value in ("y", "yes"):
            return True

        if value in ("n", "no"):
            return False

        print("Please Y ya N enter karo.")


async def delete_emojis(guild):
    print("\n[+] Deleting emojis...")

    for emoji in list(guild.emojis):
        try:
            await emoji.delete(reason="Blood Cloud clone cleanup")
            print(f"  [DELETE] Emoji: {emoji.name}")
            await asyncio.sleep(0.7)
        except discord.HTTPException as e:
            print(f"  [SKIP] Emoji {emoji.name}: {e}")


async def delete_channels(guild):
    print("\n[+] Deleting channels...")

    for channel in list(guild.channels):
        try:
            await channel.delete(reason="Blood Cloud clone cleanup")
            print(f"  [DELETE] Channel: {channel.name}")
            await asyncio.sleep(0.5)
        except discord.HTTPException as e:
            print(f"  [SKIP] Channel {channel.name}: {e}")


async def delete_categories(guild):
    print("\n[+] Deleting categories...")

    for category in list(guild.categories):
        try:
            await category.delete(reason="Blood Cloud clone cleanup")
            print(f"  [DELETE] Category: {category.name}")
            await asyncio.sleep(0.5)
        except discord.HTTPException as e:
            print(f"  [SKIP] Category {category.name}: {e}")


async def delete_roles(guild):
    print("\n[+] Deleting roles...")

    me = guild.me

    if not me:
        print("[!] Bot member not found.")
        return

    bot_position = me.top_role.position

    for role in sorted(guild.roles, key=lambda r: r.position, reverse=True):

        if role.is_default():
            continue

        if role.managed:
            print(f"  [SKIP] Managed role: {role.name}")
            continue

        if role.position >= bot_position:
            print(f"  [SKIP] Protected role: {role.name}")
            continue

        try:
            await role.delete(reason="Blood Cloud clone cleanup")
            print(f"  [DELETE] Role: {role.name}")
            await asyncio.sleep(0.5)
        except discord.HTTPException as e:
            print(f"  [SKIP] Role {role.name}: {e}")


def make_overwrites(channel, role_map):
    result = {}

    for target, overwrite in channel.overwrites.items():

        if isinstance(target, discord.Role):

            mapped = role_map.get(target.id)

            if mapped:
                result[mapped] = overwrite

    return result


async def clone_roles(source, target):
    print("\n==============================================")
    print("              CLONING ROLES")
    print("==============================================")

    role_map = {
        source.default_role.id: target.default_role
    }

    for role in sorted(source.roles, key=lambda r: r.position):

        if role.is_default():
            continue

        if role.managed:
            print(f"  [SKIP] Managed role: {role.name}")
            continue

        try:

            new_role = await target.create_role(
                name=role.name,
                permissions=role.permissions,
                colour=role.colour,
                hoist=role.hoist,
                mentionable=role.mentionable,
                reason="Blood Cloud server clone"
            )

            role_map[role.id] = new_role

            print(
                f"  [ROLE] {role.name} "
                f"| Color: #{role.color.value:06x}"
            )

            await asyncio.sleep(0.6)

        except discord.HTTPException as e:
            print(f"  [ERROR] Role {role.name}: {e}")

    # Restore role hierarchy
    for role in sorted(source.roles, key=lambda r: r.position):

        new_role = role_map.get(role.id)

        if not new_role or new_role.is_default():
            continue

        try:

            await new_role.edit(
                position=role.position,
                reason="Blood Cloud role hierarchy"
            )

            await asyncio.sleep(0.3)

        except discord.HTTPException:
            pass

    return role_map


async def clone_categories(source, target, role_map):

    print("\n==============================================")
    print("            CLONING CATEGORIES")
    print("==============================================")

    category_map = {}

    for category in source.categories:

        try:

            new_category = await target.create_category(
                name=category.name,
                overwrites=make_overwrites(
                    category,
                    role_map
                ),
                reason="Blood Cloud server clone"
            )

            category_map[category.id] = new_category

            print(f"  [CATEGORY] {category.name}")

            await asyncio.sleep(0.6)

        except discord.HTTPException as e:

            print(
                f"  [ERROR] Category "
                f"{category.name}: {e}"
            )

    return category_map


async def clone_channels(
    source,
    target,
    role_map,
    category_map
):

    print("\n==============================================")
    print("              CLONING CHANNELS")
    print("==============================================")

    for channel in source.channels:

        if isinstance(
            channel,
            discord.CategoryChannel
        ):
            continue

        category = None

        if channel.category:

            category = category_map.get(
                channel.category.id
            )

        overwrites = make_overwrites(
            channel,
            role_map
        )

        try:

            if isinstance(
                channel,
                discord.TextChannel
            ):

                await target.create_text_channel(
                    name=channel.name,
                    category=category,
                    topic=channel.topic,
                    slowmode_delay=channel.slowmode_delay,
                    nsfw=channel.nsfw,
                    overwrites=overwrites,
                    reason="Blood Cloud server clone"
                )

            elif isinstance(
                channel,
                discord.VoiceChannel
            ):

                await target.create_voice_channel(
                    name=channel.name,
                    category=category,
                    bitrate=channel.bitrate,
                    user_limit=channel.user_limit,
                    overwrites=overwrites,
                    reason="Blood Cloud server clone"
                )

            elif isinstance(
                channel,
                discord.StageChannel
            ):

                await target.create_stage_channel(
                    name=channel.name,
                    category=category,
                    overwrites=overwrites,
                    reason="Blood Cloud server clone"
                )

            else:

                print(
                    f"  [SKIP] Unsupported channel: "
                    f"{channel.name} "
                    f"({type(channel).__name__})"
                )

                continue

            print(f"  [CHANNEL] {channel.name}")

            await asyncio.sleep(0.6)

        except discord.HTTPException as e:

            print(
                f"  [ERROR] Channel "
                f"{channel.name}: {e}"
            )


async def clone_emojis(source, target):

    print("\n==============================================")
    print("               CLONING EMOJIS")
    print("==============================================")

    for emoji in source.emojis:

        try:

            image = await emoji.read()

            await target.create_custom_emoji(
                name=emoji.name,
                image=image,
                reason="Blood Cloud server clone"
            )

            print(f"  [EMOJI] {emoji.name}")

            await asyncio.sleep(1)

        except discord.HTTPException as e:

            print(
                f"  [ERROR] Emoji "
                f"{emoji.name}: {e}"
            )


async def run_clone():

    print("\n==============================================")
    print("          BLOOD CLOUD SERVER CLONER")
    print("==============================================")

    print("\nTARGET CLEANUP OPTIONS\n")

    delete_emoji = ask(
        "Do you want to delete existing EMOJIS?"
    )

    delete_channel = ask(
        "Do you want to delete existing CHANNELS?"
    )

    delete_category = ask(
        "Do you want to delete existing CATEGORIES?"
    )

    delete_role = ask(
        "Do you want to delete existing ROLES?"
    )

    print("\n==============================================")

    while True:

        try:

            source_id = int(
                input(
                    "Enter SOURCE Server ID: "
                ).strip()
            )

            break

        except ValueError:

            print(
                "Invalid ID. Sirf numbers enter karo."
            )

    while True:

        try:

            target_id = int(
                input(
                    "Enter TARGET Server ID: "
                ).strip()
            )

            break

        except ValueError:

            print(
                "Invalid ID. Sirf numbers enter karo."
            )

    source = client.get_guild(source_id)
    target = client.get_guild(target_id)

    if source is None:

        print(
            "\n[ERROR] Source server nahi mila."
        )

        return

    if target is None:

        print(
            "\n[ERROR] Target server nahi mila."
        )

        return

    print("\n==============================================")
    print(f"Source : {source.name}")
    print(f"Target : {target.name}")
    print("==============================================")

    me = target.me

    if me is None:

        print(
            "[ERROR] Bot target server mein nahi hai."
        )

        return

    if not me.guild_permissions.manage_channels:

        print(
            "[ERROR] Manage Channels permission missing."
        )

        return

    if not me.guild_permissions.manage_roles:

        print(
            "[ERROR] Manage Roles permission missing."
        )

        return

    print("\nPermissions: OK")

    print("\nSelected cleanup:")

    print(
        "Emojis    :",
        "YES" if delete_emoji else "NO"
    )

    print(
        "Channels  :",
        "YES" if delete_channel else "NO"
    )

    print(
        "Categories:",
        "YES" if delete_category else "NO"
    )

    print(
        "Roles     :",
        "YES" if delete_role else "NO"
    )

    print("\nWARNING:")
    print(
        "Target server mein selected resources "
        "delete/recreate kiye ja sakte hain."
    )

    confirm = input(
        "\nType CLONE to start: "
    ).strip()

    if confirm != "CLONE":

        print("\nClone cancelled.")

        return

    print("\n==============================================")
    print("             CLONE STARTED")
    print("==============================================")

    # Cleanup selected resources
    if delete_emoji:
        await delete_emojis(target)

    if delete_channel:
        await delete_channels(target)

    if delete_category:
        await delete_categories(target)

    if delete_role:
        await delete_roles(target)

    # Clone roles
    role_map = await clone_roles(
        source,
        target
    )

    # Clone categories
    category_map = await clone_categories(
        source,
        target,
        role_map
    )

    # Clone channels
    await clone_channels(
        source,
        target,
        role_map,
        category_map
    )

    # Clone emojis
    await clone_emojis(
        source,
        target
    )

    print("\n==============================================")
    print("          BLOOD CLOUD CLONE COMPLETE")
    print("==============================================")
    print("\nSource:", source.name)
    print("Target:", target.name)
    print("\nDone.")


@client.event
async def on_ready():

    print("\n==============================================")
    print(f"Logged in as: {client.user}")
    print(f"Bot ID: {client.user.id}")
    print("==============================================")

    try:

        await run_clone()

    except Exception as e:

        print(
            f"\n[FATAL ERROR] {type(e).__name__}: {e}"
        )

    finally:

        await client.close()


client.run(TOKEN)
PY

# ============================================================
# GITIGNORE
# ============================================================

cat > "$APP_DIR/.gitignore" <<'EOF'
.env
venv/
__pycache__/
*.pyc
EOF

# ============================================================
# START
# ============================================================

echo
echo -e "\033[1;31m============================================================\033[0m"
echo -e "\033[1;37m       BLOOD CLOUD SERVER CLONER INSTALLED\033[0m"
echo -e "\033[1;31m============================================================\033[0m"
echo

echo "[+] Starting..."

cd "$APP_DIR"

exec "$APP_DIR/venv/bin/python3" "$APP_DIR/bot.py"
