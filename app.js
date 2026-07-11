document.addEventListener('DOMContentLoaded', () => {
    const templateList = document.getElementById('template-list');
    const dynamicInputs = document.getElementById('dynamic-inputs');
    const previewSubject = document.getElementById('preview-subject');
    const previewBody = document.getElementById('preview-body');
    const copyBtn = document.getElementById('copy-btn');

    let templates = [];
    let currentTemplate = null;
    let details = {};

    // 拠点（大阪／東京）ごとに自動で切り替わる文面
    const LOCATIONS = {
        '大阪': {
            arrival: '当日は、ご利用開始時刻の【10分前】にスペースの隣にある「BALUE株式会社」までお越しください。\nスタッフにより施設の開錠、スタジオのご利用案内をさせていただきます。',
            address: '大阪府大阪市北区浪花町1-19 新興ビル5F',
            entry: '■■休日のビルへの入館について■■\n土日祝は、テナントオーナーの関係上、入り口シャッターが閉まっている可能性があります。\n入館方法をご案内しますので、到着されましたら\n事務所：06-6940-6761\n担当者：090-2069-7234（原田）\nまでお電話くださいませ。',
            notes: '（中略：事前セッティング・注意事項など）',
            contact: 'メール：contact@hakouma.jp\n電話：06-6940-6761（運営会社：BALUE株式会社／営業時間：平日 9:30〜18:30）'
        },
        '東京': {
            arrival: '当日は、ご利用開始時刻の【10分前】に会場ビル5階のスタジオ前までお越しください。\nスタッフにより施設の開錠、スタジオのご利用案内をさせていただきます。',
            address: '〒101-0021 東京都千代田区外神田1-1-13 千代田区万世橋出張所・区民館 5階 CTIB503\n\nJR秋葉原駅より徒歩3分\n銀座線神田駅より徒歩約6分\n新宿線小川町駅より徒歩約7分',
            entry: '■■ビルへの入館について■■\n施設は千代田区万世橋出張所・区民館の5階にあります。\n入館方法やビルの開錠状況についてご不明な点がございましたら、到着されましたら下記までお電話くださいませ。\n\n事務所：03-6441-2045(日本スポーツツーリズム推進機構・ジャスタ)',
            notes: '■■ご利用前のご確認・注意事項■■\n① 機材等の搬入もご利用時間内（10分前より入室可能）となります。スタジオの外はビルの共用部につき廊下などでの待機はできません。\n② ご予約いただいた代表者様は必ず開始に合わせてお越しください。代理の方へのご利用案内は致しません。（代表者様が遅れる場合は事前にご相談ください）\n③ ご利用時間内での清掃、現状復帰、完全退室をお願いします。終了時間が過ぎても退出ができない場合、別途延長料金が発生します。（通常料金の30%増）\n④ 延長や有料機材など当日のお支払いが発生した場合は、現金でのお支払いとなります。（法人の方はご請求書も可）\n\nその他、ご利用については、事前にウェブサイトより利用規約をご確認ください。\nhttps://tokyo.hakouma.jp/terms-of-service/',
            contact: 'メール：contact@selfstudio.tokyo\n電話：06-6940-6761（運営会社：BALUE株式会社／営業時間：平日 9:30〜18:30）'
        }
    };
    // 拠点によって自動計算される項目（入力欄は生成しない）
    const LOCATION_COMPUTED_KEYS = ['拠点到着案内', '拠点住所', '拠点入館案内', '拠点注意事項', '拠点問い合わせ'];

    function getLocationValues(loc) {
        const l = LOCATIONS[loc] || LOCATIONS['大阪'];
        return {
            '拠点到着案内': l.arrival,
            '拠点住所': l.address,
            '拠点入館案内': l.entry,
            '拠点注意事項': l.notes,
            '拠点問い合わせ': l.contact
        };
    }

    // Markdown ファイルからテンプレートを読み込む
    fetch('data/template_list.json')
        .then(response => response.json())
        .then(fileList => {
            const fetchPromises = fileList.map(filename =>
                fetch(`data/templates/${filename}`)
                    .then(res => res.text())
                    .then(text => parseMarkdownTemplate(filename, text))
            );
            return Promise.all(fetchPromises);
        })
        .then(loadedTemplates => {
            templates = loadedTemplates.filter(t => t !== null); // パース失敗分を除外
            renderTemplateList();
            if (templates.length > 0) {
                selectTemplate(templates[0]);
            }
        })
        .catch(err => console.error('テンプレートの読み込みに失敗しました:', err));

    function parseMarkdownTemplate(id, text) {
        try {
            // シンプルなフロントマターのパース
            const parts = text.split('---');
            if (parts.length < 3) return null;

            const metaText = parts[1];
            const body = parts.slice(2).join('---').trim();

            const nameMatch = metaText.match(/name:\s*(.+)/);
            const subjectMatch = metaText.match(/subject:\s*(.+)/);

            return {
                id: id,
                name: nameMatch ? nameMatch[1].trim() : 'Untitled',
                subject: subjectMatch ? subjectMatch[1].trim() : '',
                body: body
            };
        } catch (e) {
            console.error(`テンプレートのパースに失敗しました ${id}`, e);
            return null;
        }
    }

    function renderTemplateList() {
        templateList.innerHTML = '';
        templates.forEach(t => {
            const li = document.createElement('li');
            li.textContent = t.name;
            li.className = 'template-item';
            li.onclick = () => selectTemplate(t);
            templateList.appendChild(li);
        });
    }

    function selectTemplate(template) {
        currentTemplate = template;

        // active クラスを更新
        document.querySelectorAll('.template-item').forEach(el => {
            el.classList.toggle('active', el.textContent === template.name);
        });

        // プレースホルダーから入力欄を生成
        generateInputs(template);
        updatePreview();
    }

    function generateInputs(template) {
        dynamicInputs.innerHTML = '';
        const placeholders = extractPlaceholders(template.subject + '\n' + template.body)
            .filter(item => !LOCATION_COMPUTED_KEYS.includes(item.key));

        // 既存の値はキーが一致すれば引き継ぐ
        const newDetails = {};
        placeholders.forEach(item => {
            newDetails[item.key] = details[item.key] || resolveDefault(item.defaultValue);
        });
        details = newDetails;

        placeholders.forEach(item => {
            const field = document.createElement('div');
            field.className = 'form-field';

            const label = document.createElement('label');
            label.textContent = item.label;

            let input;
            if (item.type === 'textarea') {
                input = document.createElement('textarea');
                input.rows = 6;
            } else if (item.type === 'select') {
                input = document.createElement('select');
                item.options.forEach(opt => {
                    const optionEl = document.createElement('option');
                    optionEl.value = opt;
                    optionEl.textContent = opt;
                    input.appendChild(optionEl);
                });
            } else {
                input = document.createElement('input');
                if (item.type === 'date') {
                    input.type = 'datetime-local';
                } else if (item.type === 'time') {
                    input.type = 'time';
                } else {
                    input.type = 'text';
                }
            }

            input.value = details[item.key];

            if (item.type !== 'date' && item.type !== 'time' && item.type !== 'select') {
                input.placeholder = `${item.label}を入力`;
            }

            input.oninput = (e) => {
                details[item.key] = e.target.value;
                updatePreview();
            };
            if (item.type === 'select') {
                input.onchange = input.oninput;
            }

            field.appendChild(label);
            field.appendChild(input);
            dynamicInputs.appendChild(field);
        });
    }

    function extractPlaceholders(text) {
        // {key} / {date:key} / {time:key} / {text:key} / {select:key:opt1,opt2} / {key:default} にマッチ
        const regex = /{([^}]+)}/g;
        const matches = new Map(); // キーで重複排除
        let match;

        while ((match = regex.exec(text)) !== null) {
            const rawContent = match[1];
            let key = rawContent;
            let type = 'text';
            let defaultValue = '';
            let label = rawContent;
            let options;

            // 型プレフィックスの判定
            if (rawContent.startsWith('date:')) {
                type = 'date';
                key = rawContent.substring(5); // 'date:' を除去
                label = key;
            } else if (rawContent.startsWith('time:')) {
                type = 'time';
                key = rawContent.substring(5);
                label = key;
            } else if (rawContent.startsWith('text:')) {
                // 複数行入力（テキストエリア）
                type = 'textarea';
                key = rawContent.substring(5);
                label = key;
            } else if (rawContent.startsWith('select:')) {
                // プルダウン選択（例: select:拠点:大阪,東京）
                type = 'select';
                const rest = rawContent.substring(7);
                const sepIdx = rest.indexOf(':');
                key = sepIdx === -1 ? rest : rest.substring(0, sepIdx);
                const optionsStr = sepIdx === -1 ? '' : rest.substring(sepIdx + 1);
                options = optionsStr.split(',').map(s => s.trim()).filter(Boolean);
                defaultValue = options[0] || '';
                label = key;
            }
            // デフォルト値の判定（date: などのプレフィックスがない場合）
            else if (rawContent.includes(':')) {
                const parts = rawContent.split(':');
                key = parts[0];
                defaultValue = parts.slice(1).join(':'); // 残りをデフォルト値とする
                label = key;
            }

            if (!matches.has(key)) {
                matches.set(key, {
                    raw: rawContent,
                    key: key,
                    label: label,
                    type: type,
                    defaultValue: defaultValue,
                    options: options
                });
            }
        }
        return Array.from(matches.values());
    }

    // デフォルト値を解決する。"+Nd" は「今日から N 日後（M月D日）」に展開する。
    function resolveDefault(defaultValue) {
        if (!defaultValue) return '';
        const m = defaultValue.match(/^\+(\d+)d$/);
        if (m) {
            const days = parseInt(m[1], 10);
            const d = new Date();
            d.setDate(d.getDate() + days);
            return `${d.getMonth() + 1}月${d.getDate()}日`;
        }
        return defaultValue;
    }

    function updatePreview() {
        if (!currentTemplate) return;

        let subject = currentTemplate.subject;
        let body = currentTemplate.body;

        // 拠点（大阪／東京）の選択に応じて自動計算される項目をマージする
        const allValues = { ...details, ...getLocationValues(details['拠点']) };

        Object.keys(allValues).forEach(key => {
            // このキーに対応するプレースホルダーの全表記を置換する
            // 例: {date:利用日時} と {利用日時} はどちらも「利用日時」の値で置換

            const value = allValues[key];

            // 日付文字列（datetime-local）は表示用に整形する
            let displayValue = value;
            if (value && !isNaN(Date.parse(value)) && value.includes('T')) {
                try {
                    const dateObj = new Date(value);
                    displayValue = dateObj.toLocaleString('ja-JP', {
                        year: 'numeric', month: 'long', day: 'numeric',
                        hour: '2-digit', minute: '2-digit', weekday: 'short'
                    });
                } catch (e) { /* ignore */ }
            }

            // 1. シンプルな置換 {key}
            const simpleRegex = new RegExp(`{${key}}`, 'g');
            subject = subject.replace(simpleRegex, displayValue);
            body = body.replace(simpleRegex, displayValue);

            // 2. プレフィックス付き {prefix:key} や デフォルト付き {key:default} の置換
            const placeholders = extractPlaceholders(currentTemplate.subject + '\n' + currentTemplate.body);
            placeholders.forEach(p => {
                if (p.key === key) {
                    const escapedRaw = p.raw.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
                    const complexRegex = new RegExp(`{${escapedRaw}}`, 'g');
                    subject = subject.replace(complexRegex, displayValue);
                    body = body.replace(complexRegex, displayValue);
                }
            });
        });

        previewSubject.textContent = subject;
        previewBody.textContent = body;
    }

    copyBtn.addEventListener('click', async () => {
        const subject = previewSubject.textContent;
        const body = previewBody.textContent;
        const fullText = subject ? `件名: ${subject}\n\n${body}` : body;

        try {
            if (navigator.clipboard && window.isSecureContext) {
                await navigator.clipboard.writeText(fullText);
            } else {
                fallbackCopyText(fullText);
            }

            // 視覚的なフィードバック
            const originalText = copyBtn.textContent;
            copyBtn.textContent = 'コピーしました！';
            copyBtn.style.backgroundColor = '#10B981';

            setTimeout(() => {
                copyBtn.textContent = originalText;
                copyBtn.style.backgroundColor = '';
            }, 2000);

            // ログを保存
            saveLog(currentTemplate ? currentTemplate.name : '', subject, body);
        } catch (err) {
            console.error('クリップボードへのコピーに失敗しました:', err);
            alert('コピーに失敗しました。ブラウザの権限や HTTPS 接続をご確認ください。');
        }
    });

    function fallbackCopyText(text) {
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.setAttribute('readonly', '');
        textArea.style.position = 'fixed';
        textArea.style.opacity = '0';
        textArea.style.left = '-9999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        const success = document.execCommand('copy');
        document.body.removeChild(textArea);
        if (!success) {
            throw new Error('document.execCommand(copy) failed');
        }
    }

    function saveLog(templateName, subject, body) {
        const logData = {
            timestamp: new Date().toISOString(),
            template: templateName,
            subject: subject,
            log_body: body
        };

        try {
            const existingLogs = JSON.parse(localStorage.getItem('hakouma_mail_logs') || '[]');
            existingLogs.push(logData);
            localStorage.setItem('hakouma_mail_logs', JSON.stringify(existingLogs));
        } catch (err) {
            console.error('ログの保存に失敗しました:', err);
        }
    }

    // --- メール本文からの自動入力 ---
    const autofillToggle = document.getElementById('autofill-toggle');
    const autofillPanel = document.getElementById('autofill-panel');
    const autofillInput = document.getElementById('autofill-input');
    const autofillRun = document.getElementById('autofill-run');
    const autofillClear = document.getElementById('autofill-clear');
    const autofillMsg = document.getElementById('autofill-msg');

    autofillToggle.addEventListener('click', () => {
        if (autofillPanel.hasAttribute('hidden')) {
            autofillPanel.removeAttribute('hidden');
            autofillInput.focus();
        } else {
            autofillPanel.setAttribute('hidden', '');
        }
    });

    autofillClear.addEventListener('click', () => {
        autofillInput.value = '';
        setAutofillMsg('', '');
        autofillInput.focus();
    });

    autofillRun.addEventListener('click', () => {
        const raw = autofillInput.value;
        if (!raw.trim()) {
            setAutofillMsg('メール本文を貼り付けてください。', 'error');
            return;
        }
        const result = extractFromEmail(raw);
        if (result.error) {
            setAutofillMsg(result.error, 'error');
            return;
        }
        // 抽出値をセットしてからテンプレートを選択（入力欄が再生成され値が反映される）
        details = {};
        details['宛名'] = result.atena;
        details['予約内容'] = result.booking;
        details['ご利用料金'] = result.price;
        selectTemplate(result.template);
        setAutofillMsg(result.message, 'success');
    });

    function setAutofillMsg(text, kind) {
        autofillMsg.textContent = text;
        autofillMsg.className = 'autofill-msg' + (kind ? ' ' + kind : '');
    }

    function extractFromEmail(text) {
        // 支払い方法からテンプレートを判定
        let template = null;
        if (text.includes('銀行振込')) {
            template = templates.find(t => t.id === '01_payment_bank.md');
        } else if (text.includes('クレジットカード') || text.includes('PayPal')) {
            template = templates.find(t => t.id === '02_payment_card.md');
        }
        if (!template) {
            return { error: '支払い方法のキーワード（銀行振込／クレジットカード／PayPal）が見つかりませんでした。' };
        }

        // 会社・団体名
        let company = '';
        const companyMatch = text.match(/会社・団体名[：:]\s*(.*)/);
        if (companyMatch) {
            const c = companyMatch[1].trim();
            if (c && c !== 'なし') company = c;
        }

        // 氏名（（ふりがな）は除去）
        let name = 'ご担当者';
        const nameMatch = text.match(/氏名[：:]\s*(.*)/);
        if (nameMatch) {
            const nameClean = nameMatch[1].split(/[（(]/)[0].trim();
            if (nameClean) name = nameClean;
        }

        // 宛名（会社名 + 氏名）
        const atena = company ? `${company}\n${name}` : name;

        // ご利用料金（◎ご利用料金 以降の最初の「数字＋円」）
        let price = '';
        const headerKey = '◎ご利用料金';
        const headerIdx = text.indexOf(headerKey);
        if (headerIdx !== -1) {
            const post = text.slice(headerIdx + headerKey.length);
            const priceMatch = post.match(/([0-9,]+)円/);
            if (priceMatch) price = priceMatch[1];
        }

        // 予約内容（◎ご利用プラン 〜 ◎ご利用料金 の間）
        let booking = '';
        const bookingMatch = text.match(/◎ご利用プラン\s*\n([\s\S]*?)\n\s*◎ご利用料金/);
        if (bookingMatch) {
            booking = bookingMatch[1].trim().replace(/\n\s*\n/g, '\n\n');
        }

        // 未抽出項目の案内
        const missing = [];
        if (name === 'ご担当者') missing.push('宛名');
        if (!booking) missing.push('予約内容');
        if (!price) missing.push('ご利用料金');
        if (template.id === '02_payment_card.md') missing.push('PayPalのURL');

        let message = `自動入力しました（テンプレート：${template.name}）。拠点（大阪／東京）は自動判定できないためご確認ください。`;
        if (missing.length) {
            message += ` 未入力の項目（${missing.join('・')}）はご確認・手入力してください。`;
        }

        return { template, atena, booking, price, message };
    }
});
