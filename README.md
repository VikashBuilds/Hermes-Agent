# Hermes Agent on GitHub Actions (24/7, ₹0)

Hosts [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) on
GitHub's free runners. Uses the chaining pattern: each run lives ~5.5 hours
(6h job limit), then re-triggers itself via `workflow_dispatch`. State
(memory, skills, sessions, cron jobs) is committed back to this repo, so the
agent keeps its memories across runs forever.

- **Ubuntu runner:** 4 CPU / 16 GB RAM / 14 GB SSD
- **Telegram gateway:** talk to Hermes 24/7 from your phone
- **Autonomous cron:** Hermes' built-in scheduler runs jobs (daily briefings,
  audits...) and delivers results to Telegram
- **Cost:** ₹0 — unlimited free minutes on public repos

## Setup

1. **Create a public GitHub repo** (public = unlimited free minutes) and push
   this repo's contents into it. The `hermes-state/` folder gets created
   automatically on the first run.
2. **Add secrets** (repo Settings → Secrets and variables → Actions):

   | Secret | Required | Purpose |
   |---|---|---|
   | `TELEGRAM_BOT_TOKEN` | Yes | Your bot token from [@BotFather](https://t.me/BotFather) |
   | `TELEGRAM_ALLOWED_USERS` | Yes | Comma-separated Telegram user IDs allowed to talk to the bot |
   | `TELEGRAM_HOME_CHANNEL` | No | Chat ID for cron delivery (e.g. `-1001234567890`) |
   | `OPENCODE_ZEN_API_KEY` | Yes* | **LLM access via OpenCode Zen** — get your key at [opencode.ai/auth](https://opencode.ai/auth) |
   | `EXA_API_KEY` / `FIRECRAWL_API_KEY` | No | Web search/extract tools |
   | `FAL_KEY` | No | Image generation |
   | `GH_PAT` | No | Fallback token (scope: `repo` + `workflow`) if self-triggering hits 403 on your org |

   *At least one LLM provider key is required. `OPENCODE_ZEN_API_KEY` is the recommended one.
   Alternatives: `OPENROUTER_API_KEY`, `ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`/`GEMINI_API_KEY`,
   `NOUS_API_KEY`, `FIREWORKS_API_KEY`, `KIMI_API_KEY`, `HF_TOKEN`, `DEEPINFRA_API_KEY`.

3. **Add repo variables** (Settings → Secrets and variables → Actions → **Variables**)
   to use OpenCode Zen's free model:

   | Variable | Value |
   |---|---|
   | `HERMES_PROVIDER` | `opencode-zen` |
   | `HERMES_MODEL` | `deepseek-v4-flash-free` |

   `deepseek-v4-flash-free` is DeepSeek V4 Flash **free** ($0, 200K context) — a
   limited-time promo model on Zen. If it ever gets retired, switch the model
   (e.g. `deepseek-v4-flash`, `north-mini-code-free`, `nemotron-3-ultra-free`,
   `minimax-m2.5-free`, `big-pickle`) or drop `HERMES_PROVIDER`/`HERMES_MODEL`
   entirely for auto-detection. Other provider names work too, e.g.
   `HERMES_PROVIDER=openrouter` + `HERMES_MODEL=anthropic/claude-sonnet-4.6`.

4. **Run the workflow:** Actions tab → *Hermes Agent 24/7* → **Run workflow**.
   First run installs Hermes, restores/creates state, and starts the gateway.

5. **Talk to Hermes on Telegram.** It also self-bootstraps a few cron jobs on
   first run (you can manage them in chat — ask Hermes to add/remove schedules).

## How it stays alive 24/7

```
schedule (every 6h, backup)  ┐
                             ├─> run ~5.5h: install → restore state → bootstrap → gateway
workflow_dispatch (chained)  ┘
                                    │
                                    ▼
                     save ~/.hermes (minus secrets/binaries)
                                    │
                                    ▼
              commit + push state  →  chain next run (if none queued)
```

- `concurrency: cancel-in-progress: false` + a pre-chain check ensure runs never
  overlap or pile up.
- If a chain fails, the 6-hour cron schedule restarts the agent as a fallback.
- Watch liveness in the Actions tab or just send a Telegram message — if you
  get a reply, it's alive.

## What gets committed (and what never does)

Committed to `hermes-state/`: memory, user profile, skills, sessions DB, cron
jobs, config.

Never committed: `.env` (all API keys), `auth/` (OAuth tokens), `whatsapp/`,
`bin/`, `logs/`, the `hermes-agent` code/venv (reinstalled each run).

## Useful commands (run in any job step or locally)

```bash
hermes -z "one-shot prompt"            # scripted single prompt
hermes cron list                       # scheduled jobs
hermes send --to telegram "hello"      # send a message, no agent loop
hermes status --all                    # health check
```

## Gotchas

- **Keep the repo public** — private repos get 2,000 minutes/month, public
  ones are unlimited.
- Runs time out at 6h by design; the gateway is killed gracefully by SIGTERM
  and the next chained run takes over.
- First run downloads ~1 GB (Python, Node, tooling) — subsequent runs reuse the
  committed state, only the code/venv is reinstalled.
- If you ever want to stop the bot: disable the workflow.
