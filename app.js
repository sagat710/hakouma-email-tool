document.addEventListener('DOMContentLoaded', () => {
    const templateList = document.getElementById('template-list');
    const dynamicInputs = document.getElementById('dynamic-inputs');
    const previewSubject = document.getElementById('preview-subject');
    const previewBody = document.getElementById('preview-body');
    const copyBtn = document.getElementById('copy-btn');

    let templates = [];
    let currentTemplate = null;
    let details = {};

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
        const placeholders = extractPlaceholders(template.subject + '\n' + template.body);

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

            if (item.type !== 'date' && item.type !== 'time') {
                input.placeholder = `${item.label}を入力`;
            }

            input.oninput = (e) => {
                details[item.key] = e.target.value;
                updatePreview();
            };

            field.appendChild(label);
            field.appendChild(input);
            dynamicInputs.appendChild(field);
        });
    }

    function extractPlaceholders(text) {
        // {key} / {date:key} / {time:key} / {text:key} / {key:default} にマッチ
        const regex = /{([^}]+)}/g;
        const matches = new Map(); // キーで重複排除
        let match;

        while ((match = regex.exec(text)) !== null) {
            const rawContent = match[1];
            let key = rawContent;
            let type = 'text';
            let defaultValue = '';
            let label = rawContent;

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
                    defaultValue: defaultValue
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

        Object.keys(details).forEach(key => {
            // このキーに対応するプレースホルダーの全表記を置換する
            // 例: {date:利用日時} と {利用日時} はどちらも「利用日時」の値で置換

            const value = details[key];

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

        let message = `自動入力しました（テンプレート：${template.name}）。`;
        if (missing.length) {
            message += ` 未入力の項目（${missing.join('・')}）はご確認・手入力してください。`;
        }

        return { template, atena, booking, price, message };
    }
});
