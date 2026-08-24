/**
 * Credresolve Executive Dashboard — Chart Rendering
 * Uses Canvas API for lightweight chart rendering (no external dependencies)
 * Source of Truth: output/monthly_metrics.csv & output/analysis_results.json
 */

// ── Data (Jan–Jul 2026 complete trend: 7 months) ───────────────
const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];

// Exact Golden and Raw SUCCESS recovery values in ₹ Crore (Sum Golden = ₹111.23 Cr)
let rawRecovery = [19.11, 17.41, 19.32, 17.84, 18.70, 17.87, 19.03]; 
let goldenRecovery = [18.06, 15.94, 17.18, 15.39, 15.43, 14.53, 14.70]; 
let inflationPct = [5.5, 8.4, 11.1, 13.8, 17.5, 18.7, 22.7]; 

// Dynamic fetch from analysis_results.json if available
async function loadAnalysisData() {
    try {
        const resp = await fetch('../output/analysis_results.json');
        if (resp.ok) {
            const data = await resp.json();
            if (data.metrics && data.metrics.length >= 7) {
                const g_crs = [];
                data.metrics.slice(0, 7).forEach(m => {
                    const g = m.recovered_amount_cr || (m.recovered_amount / 1e7);
                    g_crs.push(Number(g.toFixed(2)));
                });
                if (g_crs.length === 7) {
                    goldenRecovery = g_crs;
                }
            }
        }
    } catch (e) {
        // Use static verified fallback arrays
    }
}

// ── Chart Rendering ──────────────────────────────────────────
function drawRecoveryTrend() {
    const canvas = document.getElementById('recoveryTrendChart');
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.parentElement.getBoundingClientRect();
    
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    canvas.style.width = rect.width + 'px';
    canvas.style.height = rect.height + 'px';
    ctx.scale(dpr, dpr);
    
    const w = rect.width;
    const h = rect.height;
    const pad = { top: 30, right: 20, bottom: 40, left: 60 };
    const plotW = w - pad.left - pad.right;
    const plotH = h - pad.top - pad.bottom;
    
    // Dynamic Scale (in ₹ Cr)
    const allVals = [...rawRecovery, ...goldenRecovery];
    const maxVal = Math.ceil(Math.max(...allVals) / 5) * 5; // 20 Cr
    const minVal = Math.floor(Math.min(...goldenRecovery) / 5) * 5; // 10 Cr
    
    const scaleX = (i) => pad.left + (i / (months.length - 1)) * plotW;
    const scaleY = (v) => pad.top + (1 - (v - minVal) / (maxVal - minVal)) * plotH;
    
    // Grid & Y-Axis Labels (₹10 Cr to ₹20 Cr scale)
    ctx.strokeStyle = 'rgba(42, 53, 80, 0.5)';
    ctx.lineWidth = 0.5;
    for (let i = 0; i <= 4; i++) {
        const y = pad.top + (i / 4) * plotH;
        ctx.beginPath();
        ctx.moveTo(pad.left, y);
        ctx.lineTo(w - pad.right, y);
        ctx.stroke();
        
        const val = maxVal - (i / 4) * (maxVal - minVal);
        ctx.fillStyle = '#5b6580';
        ctx.font = '11px Inter';
        ctx.textAlign = 'right';
        ctx.fillText('₹' + val.toFixed(1) + ' Cr', pad.left - 8, y + 4);
    }
    
    // X labels
    ctx.fillStyle = '#5b6580';
    ctx.font = '11px Inter';
    ctx.textAlign = 'center';
    months.forEach((m, i) => {
        ctx.fillText(m + ' 26', scaleX(i), h - pad.bottom + 20);
    });
    
    // Inflation area (shaded difference)
    ctx.beginPath();
    months.forEach((_, i) => {
        if (i === 0) ctx.moveTo(scaleX(i), scaleY(rawRecovery[i]));
        else ctx.lineTo(scaleX(i), scaleY(rawRecovery[i]));
    });
    for (let i = months.length - 1; i >= 0; i--) {
        ctx.lineTo(scaleX(i), scaleY(goldenRecovery[i]));
    }
    ctx.closePath();
    ctx.fillStyle = 'rgba(239, 68, 68, 0.12)';
    ctx.fill();
    
    // Raw line (dashed, red)
    ctx.beginPath();
    ctx.setLineDash([6, 4]);
    ctx.strokeStyle = 'rgba(239, 68, 68, 0.7)';
    ctx.lineWidth = 2;
    months.forEach((_, i) => {
        if (i === 0) ctx.moveTo(scaleX(i), scaleY(rawRecovery[i]));
        else ctx.lineTo(scaleX(i), scaleY(rawRecovery[i]));
    });
    ctx.stroke();
    ctx.setLineDash([]);
    
    // Golden line (solid, blue)
    ctx.beginPath();
    ctx.strokeStyle = '#3b82f6';
    ctx.lineWidth = 2.5;
    months.forEach((_, i) => {
        if (i === 0) ctx.moveTo(scaleX(i), scaleY(goldenRecovery[i]));
        else ctx.lineTo(scaleX(i), scaleY(goldenRecovery[i]));
    });
    ctx.stroke();
    
    // Golden dots
    months.forEach((_, i) => {
        ctx.beginPath();
        ctx.arc(scaleX(i), scaleY(goldenRecovery[i]), 4, 0, Math.PI * 2);
        ctx.fillStyle = '#3b82f6';
        ctx.fill();
        ctx.strokeStyle = '#0a0e1a';
        ctx.lineWidth = 2;
        ctx.stroke();
    });
    
    // Raw dots
    months.forEach((_, i) => {
        ctx.beginPath();
        ctx.arc(scaleX(i), scaleY(rawRecovery[i]), 3.5, 0, Math.PI * 2);
        ctx.fillStyle = '#ef4444';
        ctx.fill();
    });
    
    // Inflation labels
    ctx.font = 'bold 10px Inter';
    ctx.fillStyle = 'rgba(239, 68, 68, 0.8)';
    ctx.textAlign = 'center';
    inflationPct.forEach((pct, i) => {
        const midY = (scaleY(rawRecovery[i]) + scaleY(goldenRecovery[i])) / 2;
        ctx.fillText('+' + pct.toFixed(1) + '%', scaleX(i), midY);
    });
    
    // Legend
    const legendY = 14;
    const legendX = pad.left + 10;
    
    // Actual line
    ctx.beginPath();
    ctx.strokeStyle = '#3b82f6';
    ctx.lineWidth = 2.5;
    ctx.moveTo(legendX, legendY);
    ctx.lineTo(legendX + 25, legendY);
    ctx.stroke();
    ctx.fillStyle = '#8b95a8';
    ctx.font = '11px Inter';
    ctx.textAlign = 'left';
    ctx.fillText('Actual (Golden)', legendX + 30, legendY + 4);
    
    // Raw line
    ctx.beginPath();
    ctx.setLineDash([6, 4]);
    ctx.strokeStyle = 'rgba(239, 68, 68, 0.7)';
    ctx.lineWidth = 2;
    ctx.moveTo(legendX + 150, legendY);
    ctx.lineTo(legendX + 175, legendY);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.fillText('Reported (Raw / Inflated)', legendX + 180, legendY + 4);
    
    // Inflation label
    ctx.fillStyle = 'rgba(239, 68, 68, 0.5)';
    ctx.fillRect(legendX + 370, legendY - 6, 14, 14);
    ctx.fillStyle = '#8b95a8';
    ctx.fillText('Duplicate Inflation', legendX + 390, legendY + 4);
}

// ── Initialize ───────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
    await loadAnalysisData();
    drawRecoveryTrend();
    
    // Animate KPI cards entrance
    const kpis = document.querySelectorAll('.kpi-card');
    kpis.forEach((card, i) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(12px)';
        setTimeout(() => {
            card.style.transition = 'all 0.4s ease';
            card.style.opacity = '1';
            card.style.transform = 'translateY(0)';
        }, 80 * i);
    });
    
    // Animate channel bars
    const bars = document.querySelectorAll('.bar');
    bars.forEach((bar, i) => {
        const targetWidth = bar.style.width;
        bar.style.width = '0';
        setTimeout(() => {
            bar.style.transition = 'width 0.8s ease';
            bar.style.width = targetWidth;
        }, 600 + 100 * i);
    });
    
    // Animate funnel stages
    const stages = document.querySelectorAll('.funnel-stage');
    stages.forEach((stage, i) => {
        const targetWidth = stage.style.getPropertyValue('--width');
        stage.style.setProperty('--width', '0%');
        setTimeout(() => {
            stage.style.transition = 'all 0.5s ease';
            stage.style.setProperty('--width', targetWidth);
        }, 300 + 100 * i);
    });
});

// Redraw on resize
window.addEventListener('resize', () => {
    drawRecoveryTrend();
});
