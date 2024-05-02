sudo apt install python3
sudo apt install python3-pip
sudo pip install pyTelegramBotAPI
MYIP=$(wget -qO- ipinfo.io/ip)
systemctl stop ilyass-bot.service  > /dev/null 2>&1
rm -rf /etc/systemd/system/ilyass-bot.service
rm -rf /etc/botilyass
rm -rf /etc/systemd/system/ilyass-bot.service
mkdir /etc/botilyass
read -p "Your Bot Token: " TOKEN
read -p "Your VPS Domain: " DOMAIN
read -p "Your VPS Cloudflare Domain: " FLAREDOMAIN
read -p "Your VPS CloudFront Domain: " FRONTDOMAIN
read -p "Your VPS NS Domain: " NSDOMAIN
read -p "Your VPS PubKey: " PUBKEY

cat > /etc/botilyass/botilyass.py <<-END
import telebot
import subprocess
from datetime import datetime, timedelta

API_TOKEN = '$TOKEN'
bot = telebot.TeleBot(API_TOKEN)

# Dictionary to keep track of user's created users
user_created_users = {}

@bot.message_handler(commands=['start'])
def send_welcome(message):
    welcome_message = """Hello! Thank you for using the Free SSH Bot.

To purchase the bot, please contact @IlyassExE. With the paid version, you can create users and passwords that last for 30 days.

Press /adduser to create your free user."""

    keyboard = telebot.types.InlineKeyboardMarkup()
    contact_dev_button = telebot.types.InlineKeyboardButton(text="Contact Dev", url="https://t.me/IlyassExE")
    bot_channel_button = telebot.types.InlineKeyboardButton(text="Bot Channel", url="https://t.me/sslhtunnelmax")
    keyboard.add(contact_dev_button, bot_channel_button)

    bot.reply_to(message, welcome_message, reply_markup=keyboard)

@bot.message_handler(commands=['adduser'])
def ask_for_username(message):
    msg = bot.reply_to(message, "Send the username you want.")
    bot.register_next_step_handler(msg, save_username)

def save_username(message):
    user_id = message.from_user.id
    username = message.text

    # Check if the username already exists
    command_check_user = f'grep -c "^{username}:" /etc/passwd'
    result = subprocess.run(command_check_user, shell=True, capture_output=True, text=True)
    if int(result.stdout.strip()) > 0:
        bot.reply_to(message, "Username already exists. Please enter a different username.")
    else:
        user_created_users[user_id] = {"username": username, "count": 0}
        msg = bot.reply_to(message, "Please send the password you want.")
        bot.register_next_step_handler(msg, save_password)

def save_password(message):
    user_id = message.from_user.id
    password = message.text
    username = user_created_users[user_id]["username"]
    user_created_users[user_id]["password"] = password
    
    try:
        if user_created_users[user_id]["count"] < 3:
            # Creating user with specified username and password
            command_useradd = f'sudo useradd -m {username} -s /bin/false'
            command_passwd = f'echo "{username}:{password}" | sudo chpasswd'
            subprocess.run(command_useradd, shell=True, check=True)
            subprocess.run(command_passwd, shell=True, check=True)

            # Setting expiry date for the user
            expiry_date = (datetime.now() + timedelta(days=3)).strftime('%Y-%m-%d')
            command_expire = f'sudo usermod --expiredate {expiry_date} {username}'
            subprocess.run(command_expire, shell=True, check=True)

            # Update the count of created users for the user
            user_created_users[user_id]["count"] += 1

            response_message = """
━━━━━━━━━━━━━━━━━━━━━━
       ❑ __FREE VPS ACCOUNT__ ❑
━━━━━━━━━━━━━━━━━━━━━━
∘ SSH: \`22\`
∘ System-DNS: \`53\`
∘ SOCKS/PYTHON: \`80\` \`443\`
∘ SSL: \`443\`
∘ BadVPN: \`7200\`  \`7300\`
∘ SlowDNS: \`5300\`
∘ UDP-Custom: \`36712\`  \`1-65535\`
━━━━━━━━━━━━━━━━━━━━━━
IP-Address : \`$MYIP\`
DOMAIN  : \`$DOMAIN\`
CLOUDFLARE : \`$FLAREDOMAIN\`
CLOUDFRONT : \`$FRONTDOMAIN\`
USUARIO : \`{username}\`
PASSWD  : \`{password}\`
LIMITE  : \`2\`
VALIDEZ : \`{expiry_date}\`
━━━━━━━━━━━━━━━━━━━━━━
__• SSH Cloudflare (WS-WS-SSL) :__
\`$FLAREDOMAIN:80@{username}:{password}\`

__• SSH CloudFront (WS/WS-SSL) :__
\`$FRONTDOMAIN:80@{username}:{password}\`

__• Proxy(WS) :__
\`$DOMAIN:80@{username}:{password}\`

__• SSH UDP  :__
\`$DOMAIN:1-65535@{username}:{password}\`
━━━━━━━━━━━━━━━━━━━━━━
__•Pub KEY :__
\`$PUBKEY\`

__•NameServer (NS) :__ \`$NSDOMAIN\`
━━━━━━━━━━━━━━━━━━━━━━
""".format(username=username, password=password, expiry_date=expiry_date)
            bot.reply_to(message, response_message, parse_mode="Markdown")
        else:
            bot.reply_to(message, "You have reached the daily limit for creating users.")
    except Exception as e:
        response_message = f"Failed to add user: {str(e)}"
        bot.reply_to(message, response_message)

bot.polling()
END

cat > /etc/systemd/system/ilyass-bot.service <<-END
echo "[Unit]
Description=Telegram Bot Service By ilyass t.me/IlyassExE
After=network.target

[Service]
User=ilyass
WorkingDirectory=/etc/botilyass
ExecStart=/usr/bin/python3 botilyass.py
Restart=always

[Install]
WantedBy=multi-user.target
END

sudo systemctl daemon-reload  > /dev/null 2>&1
sudo systemctl enable ilyass-bot.service  > /dev/null 2>&1
sudo systemctl start ilyass-bot.service
echo "done ✅"
sleep 2
