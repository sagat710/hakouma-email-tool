import sys
import datetime
import pyperclip
from pathlib import Path

import re

# --- Configuration ---
TEMPLATE_DIR = Path('Templates/Studio_Reply')
MY_NAME = '原田'

def get_multiline_input():
    """Reads multiline input from the user until EOF (Ctrl+D) or empty line double enter."""
    print("【入力待機】")
    print("予約メールの本文を貼り付けてください。")
    print("入力が終わったら、Unix系なら Ctrl+D、Windowsなら Ctrl+Z を押してEnter、")
    print("または最後に『END』とだけ書いた行を入力してEnterを押してください。")
    print("-" * 40)
    
    lines = []
    try:
        while True:
            line = input()
            if line.strip() == 'END':
                break
            lines.append(line)
    except EOFError:
        pass
    
    return "\n".join(lines)

def extract_info(text):
    """
    Extracts name, price, and booking details from the text using regex.
    """
    info = {
        'name': 'ご担当者',
        'price': '【★要入力: 金額】',
        'booking_details': '【★要入力: 予約詳細】',
        'company': ''
    }
    
    # 0. Company Name Extraction (New)
    # Look for "会社・団体名：" or "会社・団体名:"
    company_match = re.search(r'会社・団体名[：:]\s*(.*)', text)
    if company_match:
        company_clean = company_match.group(1).strip()
        if company_clean and company_clean != "なし": # Ignore "None" or empty
             info['company'] = company_clean

    # 1. Name Extraction
    # Look for "氏名：" or "氏名:" pattern
    name_match = re.search(r'氏名[：:]\s*(.*)', text)
    if name_match:
        raw_name = name_match.group(1).strip()
        # Remove reading pattern ( ... ) or （ ... ）
        name_clean = re.split(r'[（\(]', raw_name)[0].strip()
        if name_clean:
            info['name'] = name_clean

    # 2. Price Extraction
    # Strategy: Find "◎ご利用料金" then look for the first price pattern after it.
    header_match = re.search(r'◎ご利用料金', text)
    if header_match:
        post_header = text[header_match.end():]
        # Find number like 22,000 or 22000 followed by 円
        price_match = re.search(r'([0-9,]+)円', post_header)
        if price_match:
            info['price'] = price_match.group(1)

    # 3. Booking Details Extraction
    # From "◎ご利用プラン" to start of "◎ご利用料金"
    pattern = r'◎ご利用プラン\s*\n(.*?)\n\s*◎ご利用料金'
    details_match = re.search(pattern, text, re.DOTALL)
    if details_match:
        raw_details = details_match.group(1).strip()
        # Clean up excessive newlines: merge multiple empty lines into one
        clean_details = re.sub(r'\n\s*\n', '\n\n', raw_details)
        if clean_details:
            info['booking_details'] = clean_details
        
    return info

def main():
    # 1. Input
    body_text = get_multiline_input()
    
    if not body_text.strip():
        print("入力がありませんでした。終了します。")
        return

    # 2. Template Selection
    template_file = None
    if "銀行振込" in body_text:
        template_file = TEMPLATE_DIR / '01_Payment_Bank.md'
        print(f"Detected: 銀行振込 -> Using {template_file.name}")
    elif "クレジットカード" in body_text or "PayPal" in body_text:
        template_file = TEMPLATE_DIR / '01_Payment_Card.md'
        print(f"Detected: クレジットカード/PayPal -> Using {template_file.name}")
    else:
        print("【該当なし】支払い方法のキーワード（銀行振込/クレジットカード/PayPal）が見つかりませんでした。")
        return

    if not template_file.exists():
        print(f"Error: テンプレートファイルが見つかりません: {template_file}")
        return

    # 3. Variable Preparation
    info = extract_info(body_text)
    deadline = datetime.datetime.now() + datetime.timedelta(days=7)
    deadline_str = deadline.strftime('%-m月%-d日')

    # Construct name field (Combine Company + Name)
    display_name = info['name']
    if info.get('company'):
        display_name = f"{info['company']}\n{info['name']}"

    # 4. Process Template
    try:
        with open(template_file, 'r', encoding='utf-8') as f:
            template_content = f.read()
        
        reply_body = template_content.format(
            name=display_name,
            my_name=MY_NAME,
            payment_deadline=deadline_str,
            price=info['price'],
            booking_details=info['booking_details'],
            paypal_link='【★要入力: PayPalリンク】'
        )
    except Exception as e:
        print(f"Error processing template: {e}")
        return

    # 5. Output
    print("\n" + "=" * 40)
    print("【生成された返信文】")
    print("-" * 40)
    print(reply_body)
    print("-" * 40)
    
    try:
        pyperclip.copy(reply_body)
        print("✅ クリップボードにコピーしました！")
    except Exception as e:
        print(f"⚠️ クリップボードへのコピーに失敗しました: {e}")
        print("手動でコピーしてください。")

if __name__ == "__main__":
    main()
