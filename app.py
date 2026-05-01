import streamlit as st
import datetime
import re
from pathlib import Path

# --- Configuration ---
# Use absolute path or relative path depending on how app is run. 
# Streamlit cloud might need adjustments, but for local use relative is fine.
TEMPLATE_DIR = Path('Templates/Studio_Reply')
MY_NAME = '原田'

# --- Logic ---

def extract_info(text):
    """
    Extracts name, company, price, and booking details from the text using regex.
    """
    info = {
        'name': 'ご担当者',
        'price': '【★要入力: 金額】',
        'booking_details': '【★要入力: 予約詳細】',
        'company': ''
    }
    
    # 0. Company Name Extraction
    # Look for "会社・団体名：" or "会社・団体名:"
    company_match = re.search(r'会社・団体名[：:]\s*(.*)', text)
    if company_match:
        company_clean = company_match.group(1).strip()
        if company_clean and company_clean != "なし": 
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

def generate_reply(body_text):
    if not body_text.strip():
        return "エラー: メール本文が入力されていません。"

    # Template Selection
    template_file = None
    if "銀行振込" in body_text:
        template_file = TEMPLATE_DIR / '01_Payment_Bank.md'
    elif "クレジットカード" in body_text or "PayPal" in body_text:
        template_file = TEMPLATE_DIR / '01_Payment_Card.md'
    else:
        return "エラー: 支払い方法のキーワード（銀行振込/クレジットカード/PayPal）が見つかりませんでした。"

    if not template_file.exists():
        # Fallback for checking relative to where command is run
        return f"エラー: テンプレートファイルが見つかりません: {template_file}"

    # Variable Preparation
    info = extract_info(body_text)
    deadline = datetime.datetime.now() + datetime.timedelta(days=7)
    deadline_str = deadline.strftime('%-m月%-d日')

    # Construct name field (Combine Company + Name)
    display_name = info['name']
    if info.get('company'):
        display_name = f"{info['company']}\n{info['name']}"

    # Process Template
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
        return reply_body
    except Exception as e:
        return f"テンプレート処理エラー: {e}"

# --- UI ---
st.set_page_config(page_title="ハコウマスタジオ 返信生成ツール", layout="centered")

st.title("ハコウマスタジオ 返信生成ツール")

# Input Area
input_text = st.text_area("予約メール本文を貼り付け", height=300, placeholder="ここにメール本文をペーストしてください...")

# Action Button
if st.button("返信案を作成", type="primary"):
    result = generate_reply(input_text)
    
    if result.startswith("エラー"):
        st.error(result)
    else:
        st.success("作成しました！")
        st.subheader("生成された返信文")
        # Display as code block to enable easy copy
        st.code(result, language='text')
