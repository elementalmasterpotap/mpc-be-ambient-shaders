using System;
using System.Drawing;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace AmbientGlow
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new SetupForm());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  ГЛАВНАЯ ФОРМА
    // ─────────────────────────────────────────────────────────────────────────
    class SetupForm : Form
    {
        // ── DWM dark title bar ──────────────────────────────────────────────
        [DllImport("dwmapi.dll")]
        static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int val, int size);

        // ── Цвета ───────────────────────────────────────────────────────────
        static readonly Color C_BG       = Color.FromArgb(28, 28, 28);
        static readonly Color C_HEADER   = Color.FromArgb(18, 18, 18);
        static readonly Color C_BORDER   = Color.FromArgb(50, 50, 50);
        static readonly Color C_LOG_BG   = Color.FromArgb(14, 14, 14);
        static readonly Color C_TEXT     = Color.FromArgb(210, 210, 210);
        static readonly Color C_MUTED    = Color.FromArgb(100, 100, 100);
        static readonly Color C_CYAN     = Color.FromArgb(0, 191, 255);
        static readonly Color C_RED      = Color.FromArgb(210, 60, 60);
        static readonly Color C_GREEN    = Color.FromArgb(60, 190, 90);
        static readonly Color C_YELLOW   = Color.FromArgb(200, 175, 60);

        // ── Пути ────────────────────────────────────────────────────────────
        readonly string exeDir;
        readonly string targetDir;
        readonly string sourceSm3;
        readonly string targetSm3;
        readonly string targetReady;
        readonly string manifest;
        readonly string prevBackup;

        // ── Локализация ─────────────────────────────────────────────────────
        readonly bool isRu;
        string S(string ru, string en) { return isRu ? ru : en; }

        // ── Контролы ────────────────────────────────────────────────────────
        Label     lblStatus;
        Label     lblLog;
        DarkButton btnInstall, btnUninstall, btnClose;

        // ── Конструктор ─────────────────────────────────────────────────────
        public SetupForm()
        {
            isRu = System.Globalization.CultureInfo.InstalledUICulture
                       .TwoLetterISOLanguageName == "ru";

            exeDir      = AppDomain.CurrentDomain.BaseDirectory;
            targetDir   = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "MPC-BE", "Shaders");
            sourceSm3   = Path.Combine(exeDir, "shaders", "ProfessionalLighting_SM3.hlsl");
            targetSm3   = Path.Combine(targetDir, "ProfessionalLighting_SM3.hlsl");
            targetReady = Path.Combine(targetDir, "AmbientGlow_SM3_Ready.hlsl");
            manifest    = Path.Combine(targetDir, "AmbientGlow_InstallManifest.json");
            prevBackup  = Path.Combine(exeDir, "docs", "ProfessionalLighting_SM3.prev.hlsl");

            InitForm();
        }

        // ── Dark title bar ───────────────────────────────────────────────────
        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            try
            {
                int dark = 1;
                DwmSetWindowAttribute(Handle, 20, ref dark, 4); // DWMWA_USE_IMMERSIVE_DARK_MODE
            }
            catch { }
        }

        // ── Инициализация формы ─────────────────────────────────────────────
        void InitForm()
        {
            Text            = "MPC-BE · Ambient Lighting";
            ClientSize      = new Size(420, 440);
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox     = false;
            BackColor       = C_BG;
            StartPosition   = FormStartPosition.CenterScreen;
            Font            = new Font("Segoe UI", 9.5f);

            // ── Шапка ───────────────────────────────────────────────────────
            var header = new Panel
            {
                BackColor = C_HEADER,
                Dock      = DockStyle.Top,
                Height    = 68,
            };

            var lblTitle = new Label
            {
                Text      = "MPC-BE · Ambient Lighting",
                Font      = new Font("Segoe UI", 13f, FontStyle.Bold),
                ForeColor = C_CYAN,
                AutoSize  = false,
                Size      = new Size(392, 30),
                Location  = new Point(16, 12),
            };

            var lblSub = new Label
            {
                Text      = S("Ambilight постобработка для MPC-BE",
                              "Ambilight post-processing for MPC-BE"),
                ForeColor = C_MUTED,
                AutoSize  = false,
                Size      = new Size(392, 20),
                Location  = new Point(16, 44),
            };

            header.Controls.AddRange(new Control[] { lblTitle, lblSub });

            // ── Статус ──────────────────────────────────────────────────────
            lblStatus = new Label
            {
                AutoSize  = false,
                Size      = new Size(392, 22),
                Location  = new Point(16, 84),
                Font      = new Font("Segoe UI", 9.5f),
            };

            // ── Кнопки ──────────────────────────────────────────────────────
            btnInstall = new DarkButton
            {
                Text        = S("Установить", "Install"),
                Location    = new Point(16, 116),
                Size        = new Size(388, 44),
                AccentColor = C_CYAN,
                ForeColor   = C_TEXT,
            };
            btnInstall.Click += (s, e) => DoInstall();

            btnUninstall = new DarkButton
            {
                Text        = S("Удалить", "Uninstall"),
                Location    = new Point(16, 168),
                Size        = new Size(388, 44),
                AccentColor = C_RED,
                ForeColor   = C_TEXT,
            };
            btnUninstall.Click += (s, e) => DoUninstall();

            btnClose = new DarkButton
            {
                Text        = S("Закрыть", "Close"),
                Location    = new Point(16, 220),
                Size        = new Size(388, 44),
                AccentColor = C_BORDER,
                ForeColor   = C_MUTED,
            };
            btnClose.Click += (s, e) => Close();

            // ── Инструкция ──────────────────────────────────────────────────
            var sep = new Panel
            {
                BackColor = C_BORDER,
                Location  = new Point(0, 274),
                Size      = new Size(420, 1),
            };

            var lblGuideTitle = new Label
            {
                Text      = S("Как включить в MPC-BE:", "How to enable in MPC-BE:"),
                ForeColor = C_MUTED,
                AutoSize  = false,
                Size      = new Size(392, 20),
                Location  = new Point(16, 283),
                Font      = new Font("Segoe UI", 8.5f),
            };

            var lblStep1 = new Label
            {
                Text      = S("1. Откройте MPC-BE", "1. Open MPC-BE"),
                ForeColor = C_TEXT,
                AutoSize  = false,
                Size      = new Size(392, 18),
                Location  = new Point(16, 308),
                Font      = new Font("Segoe UI", 9f),
            };

            var lblStep2 = new Label
            {
                Text      = S("2. Вид  \u2192  Шейдер  \u2192  Постобработка",
                              "2. View  \u2192  Shader  \u2192  Post-Processing"),
                ForeColor = C_TEXT,
                AutoSize  = false,
                Size      = new Size(392, 18),
                Location  = new Point(16, 328),
                Font      = new Font("Segoe UI", 9f),
            };

            var lblStep3 = new Label
            {
                Text      = S("3. Выберите  ", "3. Select  "),
                ForeColor = C_TEXT,
                AutoSize  = true,
                Location  = new Point(16, 348),
                Font      = new Font("Segoe UI", 9f),
            };

            var lblShaderName = new Label
            {
                Text      = "AmbientGlow_SM3_Ready.hlsl",
                ForeColor = C_CYAN,
                AutoSize  = true,
                Location  = new Point(16 + lblStep3.PreferredWidth, 348),
                Font      = new Font("Segoe UI", 9f),
            };

            var lblStep4 = new Label
            {
                Text      = S("4. Нажмите OK — эффект применится сразу",
                              "4. Click OK — effect applies immediately"),
                ForeColor = C_TEXT,
                AutoSize  = false,
                Size      = new Size(392, 18),
                Location  = new Point(16, 368),
                Font      = new Font("Segoe UI", 9f),
            };

            var lblNote = new Label
            {
                Text      = S("Рекомендуется ночной билд: github.com/Aleksoid1978/MPC-BE",
                              "Nightly build recommended: github.com/Aleksoid1978/MPC-BE"),
                ForeColor = Color.FromArgb(75, 75, 75),
                AutoSize  = false,
                Size      = new Size(392, 16),
                Location  = new Point(16, 392),
                Font      = new Font("Segoe UI", 8f),
            };

            // ── Лог-панель ──────────────────────────────────────────────────
            var logPanel = new Panel
            {
                BackColor = C_LOG_BG,
                Dock      = DockStyle.Bottom,
                Height    = 36,
            };

            lblLog = new Label
            {
                Text      = S("> Готово к установке", "> Ready to install"),
                ForeColor = C_MUTED,
                AutoSize  = false,
                Size      = new Size(410, 36),
                Location  = new Point(10, 0),
                TextAlign = ContentAlignment.MiddleLeft,
                Font      = new Font("Consolas", 8.5f),
            };

            logPanel.Controls.Add(lblLog);

            Controls.AddRange(new Control[]
            {
                header, lblStatus, btnInstall, btnUninstall, btnClose,
                sep, lblGuideTitle, lblStep1, lblStep2, lblStep3, lblShaderName,
                lblStep4, lblNote, logPanel
            });

            UpdateStatus();
        }

        // ─────────────────────────────────────────────────────────────────────
        //  ХЕЛПЕРЫ
        // ─────────────────────────────────────────────────────────────────────
        bool IsInstalled()
        {
            return File.Exists(manifest) && File.Exists(targetReady);
        }

        void UpdateStatus()
        {
            if (IsInstalled())
            {
                lblStatus.Text      = S("● Установлен", "● Installed");
                lblStatus.ForeColor = C_GREEN;
            }
            else
            {
                lblStatus.Text      = S("○ Не установлен", "○ Not installed");
                lblStatus.ForeColor = C_MUTED;
            }
        }

        void Log(string msg, Color? color = null)
        {
            lblLog.ForeColor = color ?? C_TEXT;
            lblLog.Text      = "> " + msg;
        }

        void SetBusy(bool busy)
        {
            btnInstall.Enabled   = !busy;
            btnUninstall.Enabled = !busy;
            btnClose.Enabled     = !busy;
            Application.DoEvents();
        }

        // ─────────────────────────────────────────────────────────────────────
        //  УСТАНОВКА
        // ─────────────────────────────────────────────────────────────────────
        void DoInstall()
        {
            SetBusy(true);
            Log(S("Установка...", "Installing..."), C_CYAN);

            try
            {
                if (!File.Exists(sourceSm3))
                    throw new FileNotFoundException(
                        S("Файл шейдера не найден: " + sourceSm3,
                          "Shader file not found: " + sourceSm3));

                Directory.CreateDirectory(targetDir);

                // бэкап prev.hlsl
                var docsDir = Path.Combine(exeDir, "docs");
                if (Directory.Exists(docsDir))
                    File.Copy(sourceSm3, prevBackup, true);

                // копируем шейдер
                File.Copy(sourceSm3, targetSm3, true);

                // Ready-файл с заголовком
                string hdr = "// AUTO-GENERATED FOR INSTANT USE\r\n" +
                             "// Profile: Ultra Quality SM3\r\n" +
                             "// Source: ProfessionalLighting_SM3.hlsl\r\n\r\n";
                File.WriteAllText(
                    targetReady,
                    hdr + File.ReadAllText(sourceSm3),
                    new System.Text.UTF8Encoding(true));

                // JSON манифест
                string now  = DateTime.Now.ToString("s");
                string json = "{\r\n" +
                              "  \"installedAt\": \"" + now + "\",\r\n" +
                              "  \"profile\": \"UltraQuality_SM3\",\r\n" +
                              "  \"files\": [\"ProfessionalLighting_SM3.hlsl\", \"AmbientGlow_SM3_Ready.hlsl\"]\r\n" +
                              "}";
                File.WriteAllText(manifest, json, new System.Text.UTF8Encoding(true));

                UpdateStatus();
                Log(S("Готово. Шейдер установлен.", "Done. Shader installed."), C_GREEN);
            }
            catch (Exception ex)
            {
                Log(S("Ошибка: ", "Error: ") + ex.Message, C_RED);
            }
            finally
            {
                SetBusy(false);
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        //  УДАЛЕНИЕ
        // ─────────────────────────────────────────────────────────────────────
        void DoUninstall()
        {
            SetBusy(true);
            Log(S("Удаление...", "Removing..."), C_YELLOW);

            try
            {
                string[] files = GetFileList();
                int removed = 0;

                foreach (var name in files)
                {
                    var path = Path.Combine(targetDir, name);
                    if (File.Exists(path))
                    {
                        File.Delete(path);
                        removed++;
                    }
                }

                UpdateStatus();
                if (removed > 0)
                    Log(S("Удалено файлов: " + removed + ".", "Removed: " + removed + " file(s)."), C_GREEN);
                else
                    Log(S("Файлы не найдены. Ничего не удалено.", "No files found. Nothing removed."), C_MUTED);
            }
            catch (Exception ex)
            {
                Log(S("Ошибка: ", "Error: ") + ex.Message, C_RED);
            }
            finally
            {
                SetBusy(false);
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        //  СПИСОК ФАЙЛОВ ДЛЯ УДАЛЕНИЯ
        // ─────────────────────────────────────────────────────────────────────
        string[] GetFileList()
        {
            string[] fallback = {
                "ProfessionalLighting_SM3.hlsl",
                "AmbientGlow_SM3_Ready.hlsl",
                "AmbientGlow_InstallManifest.json"
            };

            if (!File.Exists(manifest)) return fallback;

            try
            {
                string json = File.ReadAllText(manifest);
                string[] items = ParseJsonStringArray(json, "files");
                if (items != null && items.Length > 0)
                {
                    var list = new List<string>(items);
                    if (!list.Contains("AmbientGlow_InstallManifest.json"))
                        list.Add("AmbientGlow_InstallManifest.json");
                    return list.ToArray();
                }
            }
            catch { }

            return fallback;
        }

        // минималистичный парсер JSON массива строк (без внешних зависимостей)
        string[] ParseJsonStringArray(string json, string key)
        {
            int ki = json.IndexOf("\"" + key + "\"");
            if (ki < 0) return null;
            int lb = json.IndexOf('[', ki);
            int rb = json.IndexOf(']', lb < 0 ? 0 : lb);
            if (lb < 0 || rb < 0) return null;
            string inner = json.Substring(lb + 1, rb - lb - 1);
            var items = new List<string>();
            int i = 0;
            while (i < inner.Length)
            {
                int q1 = inner.IndexOf('"', i);
                if (q1 < 0) break;
                int q2 = inner.IndexOf('"', q1 + 1);
                if (q2 < 0) break;
                items.Add(inner.Substring(q1 + 1, q2 - q1 - 1));
                i = q2 + 1;
            }
            return items.ToArray();
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  ТЁМНАЯ КНОПКА
    // ─────────────────────────────────────────────────────────────────────────
    class DarkButton : Button
    {
        public Color AccentColor { get; set; }

        bool _hover;
        bool _press;

        static readonly Color BG_NORMAL = Color.FromArgb(36, 36, 36);
        static readonly Color BG_HOVER  = Color.FromArgb(44, 44, 44);

        public DarkButton()
        {
            AccentColor = Color.FromArgb(50, 50, 50);
            FlatStyle = FlatStyle.Flat;
            FlatAppearance.BorderSize = 0;
            UseVisualStyleBackColor = false;
            BackColor = BG_NORMAL;
            Cursor    = Cursors.Hand;
            Font      = new Font("Segoe UI", 10f);
            TextAlign = ContentAlignment.MiddleCenter;
        }

        protected override void OnMouseEnter(EventArgs e)
        { _hover = true;  Invalidate(); base.OnMouseEnter(e); }

        protected override void OnMouseLeave(EventArgs e)
        { _hover = false; _press = false; Invalidate(); base.OnMouseLeave(e); }

        protected override void OnMouseDown(MouseEventArgs e)
        { _press = true;  Invalidate(); base.OnMouseDown(e); }

        protected override void OnMouseUp(MouseEventArgs e)
        { _press = false; Invalidate(); base.OnMouseUp(e); }

        protected override void OnPaint(PaintEventArgs e)
        {
            var g = e.Graphics;
            var r = ClientRectangle;

            // фон
            var bg = _press ? AccentColor : _hover ? BG_HOVER : BG_NORMAL;
            using (var br = new SolidBrush(bg))
                g.FillRectangle(br, r);

            // рамка
            var bc = _hover ? AccentColor : Color.FromArgb(48, 48, 48);
            using (var pen = new Pen(bc, 1))
                g.DrawRectangle(pen, 0, 0, r.Width - 1, r.Height - 1);

            // текст
            var fc = _press ? Color.FromArgb(22, 22, 22)
                   : _hover ? AccentColor
                   : ForeColor;
            TextRenderer.DrawText(g, Text, Font, r, fc,
                TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
        }
    }
}
