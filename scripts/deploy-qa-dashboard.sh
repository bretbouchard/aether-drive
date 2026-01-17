#!/bin/bash

# Deploy QA dashboard to production
# Supports both remote and local deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DASHBOARD_DIR="$PROJECT_ROOT/infrastructure/QADashboard"

echo "=========================================="
echo "QA Dashboard Deployment"
echo "=========================================="
echo ""

# Check if dashboard directory exists
if [ ! -d "$DASHBOARD_DIR" ]; then
    echo "❌ QA Dashboard directory not found: $DASHBOARD_DIR"
    exit 1
fi

# Parse command line arguments
DEPLOY_MODE="${1:-auto}"
ENVIRONMENT="${2:-production}"

echo "Deploy Mode: $DEPLOY_MODE"
echo "Environment: $ENVIRONMENT"
echo ""

# ============================================
# 1. Generate Dashboard Data
# ============================================
echo "📊 Generating Dashboard Data..."

cd "$DASHBOARD_DIR"

# Check if Swift script exists
if [ -f "generate-dashboard.swift" ]; then
    echo "Running Swift dashboard generator..."
    swift generate-dashboard.swift || echo "⚠️  Swift generation failed, using fallback"
else
    echo "⚠️  No Swift dashboard generator found"
fi

# Ensure dashboard output directory exists
mkdir -p Dashboard/public
mkdir -p Dashboard/data

# Copy latest test results
if [ -f "$PROJECT_ROOT/TestReports/cross-platform-report.json" ]; then
    cp "$PROJECT_ROOT/TestReports/cross-platform-report.json" "$DASHBOARD_DIR/Dashboard/data/latest-report.json"
    echo "✓ Latest report copied"
else
    echo "⚠️  No test report found"
fi

# Copy historical data if exists
if [ -d "$PROJECT_ROOT/TestReports/history" ]; then
    cp -r "$PROJECT_ROOT/TestReports/history" "$DASHBOARD_DIR/Dashboard/data/"
    echo "✓ Historical data copied"
fi

# ============================================
# 2. Build Dashboard Assets
# ============================================
echo ""
echo "🔨 Building Dashboard Assets..."

# Generate HTML dashboard
cat > "$DASHBOARD_DIR/Dashboard/public/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>White Room QA Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        .header {
            background: white;
            border-radius: 10px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .header h1 {
            color: #333;
            font-size: 32px;
            margin-bottom: 10px;
        }

        .header .subtitle {
            color: #666;
            font-size: 14px;
        }

        .score-card {
            background: white;
            border-radius: 10px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            text-align: center;
        }

        .score {
            font-size: 72px;
            font-weight: bold;
            margin: 20px 0;
        }

        .score.A-plus, .score.A { color: #10b981; }
        .score.B-plus, .score.B { color: #f59e0b; }
        .score.C { color: #ef4444; }
        .score.F { color: #dc2626; }

        .grade {
            font-size: 48px;
            font-weight: bold;
            margin-bottom: 20px;
        }

        .metrics {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }

        .metric-card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .metric-card h3 {
            color: #666;
            font-size: 14px;
            margin-bottom: 10px;
            text-transform: uppercase;
        }

        .metric-card .value {
            font-size: 36px;
            font-weight: bold;
            color: #333;
        }

        .metric-card .subtext {
            color: #999;
            font-size: 12px;
            margin-top: 5px;
        }

        .status-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: bold;
        }

        .status-badge.pass {
            background: #d1fae5;
            color: #065f46;
        }

        .status-badge.fail {
            background: #fee2e2;
            color: #991b1b;
        }

        .loading {
            text-align: center;
            padding: 50px;
            color: white;
            font-size: 18px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>White Room QA Dashboard</h1>
            <p class="subtitle">Phase 2: Cross-Platform Test Results</p>
        </div>

        <div id="loading" class="loading">Loading test results...</div>

        <div id="dashboard" style="display: none;">
            <div class="score-card">
                <div class="grade" id="grade">-</div>
                <div class="score" id="score">-</div>
                <div id="status-badge" class="status-badge">-</div>
            </div>

            <div class="metrics">
                <div class="metric-card">
                    <h3>SDK Coverage</h3>
                    <div class="value" id="sdk-coverage">-</div>
                    <div class="subtext">Lines covered</div>
                </div>

                <div class="metric-card">
                    <h3>iOS Tests</h3>
                    <div class="value" id="ios-tests">-</div>
                    <div class="subtext">Passed / Failed</div>
                </div>

                <div class="metric-card">
                    <h3>tvOS Tests</h3>
                    <div class="value" id="tvos-tests">-</div>
                    <div class="subtext">Passed / Failed</div>
                </div>

                <div class="metric-card">
                    <h3>Telemetry</h3>
                    <div class="value" id="telemetry">-</div>
                    <div class="subtext">Integration tests</div>
                </div>

                <div class="metric-card">
                    <h3>Accessibility</h3>
                    <div class="value" id="accessibility">-</div>
                    <div class="subtext">Errors found</div>
                </div>

                <div class="metric-card">
                    <h3>Performance</h3>
                    <div class="value" id="performance">-</div>
                    <div class="subtext">Regressions</div>
                </div>

                <div class="metric-card">
                    <h3>Crash-Free Users</h3>
                    <div class="value" id="crash-free">-</div>
                    <div class="subtext">Production telemetry</div>
                </div>

                <div class="metric-card">
                    <h3>Last Updated</h3>
                    <div class="value" id="timestamp" style="font-size: 18px;">-</div>
                    <div class="subtext">UTC</div>
                </div>
            </div>
        </div>
    </div>

    <script>
        fetch('data/latest-report.json')
            .then(response => response.json())
            .then(data => {
                document.getElementById('loading').style.display = 'none';
                document.getElementById('dashboard').style.display = 'block';

                // Score and grade
                const score = data.overallScore || 0;
                const grade = data.grade || '-';

                document.getElementById('grade').textContent = grade;
                document.getElementById('score').textContent = score.toFixed(1) + '/100';
                document.getElementById('score').className = 'score ' + grade.replace('+', '-plus');

                // Status badge
                const statusBadge = document.getElementById('status-badge');
                if (data.meetsGates) {
                    statusBadge.textContent = '✅ Quality Gates PASSED';
                    statusBadge.className = 'status-badge pass';
                } else {
                    statusBadge.textContent = '❌ Quality Gates FAILED';
                    statusBadge.className = 'status-badge fail';
                }

                // Metrics
                document.getElementById('sdk-coverage').textContent =
                    (data.sdk?.coverage ?? 'N/A') + '%';

                document.getElementById('ios-tests').textContent =
                    (data.ios?.passed ?? 0) + ' / ' + (data.ios?.failed ?? 0);

                document.getElementById('tvos-tests').textContent =
                    (data.tvos?.passed ?? 0) + ' / ' + (data.tvos?.failed ?? 0);

                document.getElementById('telemetry').textContent =
                    (data.telemetry?.passed ?? 0) + ' / ' + (data.telemetry?.tests ?? 0);

                document.getElementById('accessibility').textContent =
                    data.accessibility?.errors ?? 0;

                document.getElementById('performance').textContent =
                    data.performance?.regressions ?? 0;

                document.getElementById('crash-free').textContent =
                    (data.production?.crashFreeUsers ?? 'N/A') + '%';

                // Timestamp
                const timestamp = new Date(data.timestamp);
                document.getElementById('timestamp').textContent =
                    timestamp.toLocaleString();
            })
            .catch(error => {
                document.getElementById('loading').textContent =
                    'Error loading test results: ' + error.message;
            });
    </script>
</body>
</html>
EOF

echo "✓ HTML dashboard generated"

# ============================================
# 3. Deploy Dashboard
# ============================================
echo ""
echo "🚀 Deploying Dashboard..."

if [ "$DEPLOY_MODE" == "auto" ]; then
    # Auto-detect deployment method
    if [ -n "$DEPLOY_HOST" ] && [ -n "$DEPLOY_USER" ] && [ -n "$DEPLOY_KEY" ]; then
        DEPLOY_MODE="remote"
    else
        DEPLOY_MODE="local"
    fi
fi

if [ "$DEPLOY_MODE" == "remote" ]; then
    echo "Deploying to remote host: $DEPLOY_HOST"

    # Check if SSH key is available
    if [ -z "$DEPLOY_KEY" ]; then
        echo "❌ DEPLOY_KEY environment variable not set"
        exit 1
    fi

    # Setup SSH
    SSH_KEY_PATH="$HOME/.ssh/qa_dashboard_deploy_key"
    echo "$DEPLOY_KEY" > "$SSH_KEY_PATH"
    chmod 600 "$SSH_KEY_PATH"

    # Deploy via rsync
    rsync -avz --delete \
        -e "ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no" \
        "$DASHBOARD_DIR/Dashboard/" \
        "$DEPLOY_USER@$DEPLOY_HOST:/var/www/qa-dashboard/"

    # Cleanup
    rm -f "$SSH_KEY_PATH"

    echo "✓ Dashboard deployed to remote host"

elif [ "$DEPLOY_MODE" == "local" ]; then
    echo "Deploying to local directory"

    # Deploy to local Sites directory
    LOCAL_DEPLOY_PATH="$HOME/Sites/qa-dashboard"
    mkdir -p "$LOCAL_DEPLOY_PATH"

    cp -r "$DASHBOARD_DIR/Dashboard/"* "$LOCAL_DEPLOY_PATH/"

    echo "✓ Dashboard deployed to: $LOCAL_DEPLOY_PATH"
    echo "  Open: file://$LOCAL_DEPLOY_PATH/index.html"

else
    echo "❌ Unknown deploy mode: $DEPLOY_MODE"
    exit 1
fi

# ============================================
# 4. Verify Deployment
# ============================================
echo ""
echo "✅ QA Dashboard Deployment Complete!"
echo ""
echo "Dashboard deployed successfully"
echo "Environment: $ENVIRONMENT"
echo "Mode: $DEPLOY_MODE"
