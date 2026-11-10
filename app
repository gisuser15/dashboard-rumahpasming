/**
 * Dashboard Pembangunan Rumah Pasar Minggu
 * Real-time construction analytics & expense tracking
 */

// State variables
let currentData = window.REALISASI_DATA || {
  project: { title: "Pembangunan Rumah Pasar Minggu", location: "Jati Padang, Pasar Minggu", area: "30 m²" },
  funding: { saldoAwal: 114000000, totalPengeluaran: 190693643, saldoAkhir: -76663643 },
  categories: [],
  milestones: [],
  transactions: []
};

let filteredTransactions = [];
let currentPage = 1;
let itemsPerPage = 20;
let categoryDonutChart = null;
let categoryBarChart = null;

// Currency & Number Formatter
function formatRupiah(number) {
  if (number === null || number === undefined || isNaN(number)) return "Rp 0";
  const isNegative = number < 0;
  const absVal = Math.abs(Math.round(number));
  const formatted = new Intl.NumberFormat('id-ID').format(absVal);
  return (isNegative ? "-Rp " : "Rp ") + formatted;
}

function formatNumber(number) {
  if (number === null || number === undefined || isNaN(number)) return "0";
  return new Intl.NumberFormat('id-ID').format(number);
}

// Show Toast
function showToast(message) {
  const toast = document.getElementById('toast');
  const msgEl = document.getElementById('toast-message');
  if (!toast || !msgEl) return;
  msgEl.textContent = message;
  toast.classList.remove('opacity-0', 'translate-y-20', 'pointer-events-none');
  setTimeout(() => {
    toast.classList.add('opacity-0', 'translate-y-20', 'pointer-events-none');
  }, 3500);
}

// Switch Active Tab
function switchTab(tabId) {
  // Update Buttons
  document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.classList.remove('active', 'bg-sky-500/10', 'text-sky-400', 'border', 'border-sky-500/30');
    btn.classList.add('text-slate-400');
  });
  const activeBtn = document.getElementById(`tab-btn-${tabId}`);
  if (activeBtn) {
    activeBtn.classList.add('active', 'bg-sky-500/10', 'text-sky-400', 'border', 'border-sky-500/30');
    activeBtn.classList.remove('text-slate-400');
  }

  // Update Panes
  document.querySelectorAll('.tab-pane').forEach(pane => {
    pane.classList.add('hidden');
  });
  const activePane = document.getElementById(`tab-content-${tabId}`);
  if (activePane) {
    activePane.classList.remove('hidden');
  }

  // If switched to dashboard, redraw charts to prevent size glitches
  if (tabId === 'dashboard') {
    setTimeout(() => {
      if (categoryDonutChart) categoryDonutChart.resize();
      if (categoryBarChart) categoryBarChart.resize();
    }, 50);
  }
}

// Initialize Charts
function initCharts() {
  if (typeof Chart === 'undefined') {
    console.warn('Chart.js CDN belum termuat atau koneksi offline.');
    return;
  }
  const categories = currentData.categories || [];
  if (categories.length === 0) return;

  const labels = categories.map(c => `${c.code}. ${c.name.toUpperCase()}`);
  const shortLabels = categories.map(c => {
    return c.name
      .replace(/^PEKERJAAN\s+/i, '')
      .replace(/^BIAYA\s+/i, '')
      .replace(/PINTU,\s*JENDELA\s*ALUMINIUM,\s*DLL/i, 'PINTU & KUSEN')
      .replace(/MEKANIKAL\s+ELEKTRIKAL/i, 'LISTRIK')
      .replace(/STRUKTUR\s+&\s+DINDING/i, 'STRUKTUR & DINDING')
      .trim()
      .toUpperCase();
  });
  const totals = categories.map(c => c.total);

  // Modern Architectural Palette
  const chartColors = [
    '#0ea5e9', // Sumur Air (Sky)
    '#f59e0b', // Tukang (Amber)
    '#6366f1', // Struktur (Indigo)
    '#3b82f6', // Dag Lt 2 (Blue)
    '#8b5cf6', // Dinding Lt 2 (Purple)
    '#ec4899', // Atap (Pink)
    '#10b981', // Saluran Air (Emerald)
    '#14b8a6', // Pintu & Aluminium (Teal)
    '#f97316'  // Elektrikal (Orange)
  ];

  // 1. Donut Chart
  const donutCtx = document.getElementById('categoryDonutChart');
  if (donutCtx) {
    if (categoryDonutChart) categoryDonutChart.destroy();
    categoryDonutChart = new Chart(donutCtx, {
      type: 'doughnut',
      data: {
        labels: shortLabels,
        datasets: [{
          data: totals,
          backgroundColor: chartColors,
          borderWidth: 2,
          borderColor: '#0b1329',
          hoverOffset: 8
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'right',
            labels: {
              color: '#94a3b8',
              font: { family: "'Plus Jakarta Sans', sans-serif", size: 11 },
              boxWidth: 12,
              padding: 12
            }
          },
          tooltip: {
            backgroundColor: '#0f172a',
            titleColor: '#e2e8f0',
            bodyColor: '#38bdf8',
            borderColor: '#334155',
            borderWidth: 1,
            padding: 12,
            callbacks: {
              label: function(context) {
                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                const val = context.raw || 0;
                const pct = ((val / total) * 100).toFixed(1);
                return ` ${formatRupiah(val)} (${pct}%)`;
              }
            }
          }
        },
        cutout: '68%'
      }
    });
  }

  // 2. Bar Chart
  const barCtx = document.getElementById('categoryBarChart');
  if (barCtx) {
    if (categoryBarChart) categoryBarChart.destroy();
    categoryBarChart = new Chart(barCtx, {
      type: 'bar',
      data: {
        labels: shortLabels,
        datasets: [{
          label: 'Total Biaya',
          data: totals,
          backgroundColor: chartColors.map(c => c + 'cc'),
          hoverBackgroundColor: chartColors,
          borderRadius: 8,
          borderSkipped: false
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: '#0f172a',
            titleColor: '#e2e8f0',
            bodyColor: '#38bdf8',
            borderColor: '#334155',
            borderWidth: 1,
            padding: 12,
            callbacks: {
              label: function(context) {
                return ` Biaya: ${formatRupiah(context.raw)}`;
              }
            }
          }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: {
              color: '#94a3b8',
              font: { family: "'Plus Jakarta Sans', sans-serif", size: 10 }
            }
          },
          y: {
            grid: { color: 'rgba(255, 255, 255, 0.05)' },
            ticks: {
              color: '#94a3b8',
              font: { family: "'Plus Jakarta Sans', sans-serif", size: 10 },
              callback: function(val) {
                return (val / 1000000).toFixed(0) + ' Jt';
              }
            }
          }
        }
      }
    });
  }
}

// Render 9 Category Cards on Dashboard
function renderCategoryCards() {
  const container = document.getElementById('categories-card-grid');
  if (!container) return;

  const totalExpense = currentData.funding?.totalPengeluaran || 190693643;
  const categories = currentData.categories || [];

  container.innerHTML = categories.map(cat => {
    const pct = ((cat.total / totalExpense) * 100).toFixed(1);
    return `
      <div onclick="filterByCategoryCode('${cat.code}')" class="bg-slate-900/70 hover:bg-slate-800/80 p-4 rounded-xl border border-slate-800/80 hover:border-sky-500/40 cursor-pointer transition-all group">
        <div class="flex items-center justify-between mb-2">
          <span class="inline-flex items-center justify-center w-7 h-7 rounded-lg bg-sky-950 text-sky-400 font-bold text-xs border border-sky-800/50">
            ${cat.code}
          </span>
          <span class="text-xs font-semibold text-slate-400 group-hover:text-sky-300">
            ${pct}%
          </span>
        </div>
        <div class="font-semibold text-xs text-slate-200 line-clamp-1 group-hover:text-white uppercase" title="${cat.name.toUpperCase()}">
          ${cat.name.toUpperCase()}
        </div>
        <div class="text-base font-extrabold text-white mt-1">
          ${formatRupiah(cat.total)}
        </div>
        <div class="mt-2.5 flex items-center justify-between text-[11px] text-slate-400">
          <span>${cat.itemCount} Item belanja</span>
          <span class="text-sky-400 flex items-center gap-1 group-hover:translate-x-0.5 transition-transform">
            Filter <i data-lucide="chevron-right" class="w-3 h-3"></i>
          </span>
        </div>
        <div class="w-full bg-slate-800 rounded-full h-1.5 mt-2 overflow-hidden">
          <div class="bg-gradient-to-r from-sky-500 to-indigo-500 h-1.5 rounded-full" style="width: ${Math.min(pct * 2.2, 100)}%"></div>
        </div>
      </div>
    `;
  }).join('');

  if (window.lucide) lucide.createIcons();
}

// Render Mini Timeline Strip on Dashboard
function renderMiniMilestones() {
  const container = document.getElementById('milestones-mini-grid');
  if (!container) return;

  const milestones = currentData.milestones || [];
  container.innerHTML = milestones.map(m => `
    <div class="bg-slate-900/60 p-3.5 rounded-xl border border-slate-800/70 hover:border-indigo-500/30 transition">
      <div class="flex items-center justify-between text-[11px] text-slate-400 mb-1">
        <span class="px-2 py-0.5 rounded bg-indigo-950/80 text-indigo-400 font-semibold border border-indigo-800/40">Tahap ${m.no}</span>
        <span class="text-emerald-400 font-medium">${m.duration}</span>
      </div>
      <div class="font-bold text-xs text-white mt-1">${m.stage}</div>
      <div class="text-[11px] text-slate-400 mt-1">${m.startDate} - ${m.endDate}</div>
    </div>
  `).join('');
}

// Render Full Timeline Tab
function renderFullTimeline() {
  const container = document.getElementById('timeline-stepper-container');
  if (!container) return;

  const milestones = currentData.milestones || [];
  container.innerHTML = milestones.map(m => `
    <div class="relative group">
      <!-- Dot on vertical line -->
      <div class="absolute -left-[33px] sm:-left-[41px] top-1.5 w-6 h-6 rounded-full bg-slate-950 border-2 border-indigo-500 flex items-center justify-center text-[10px] font-bold text-indigo-400 group-hover:scale-110 group-hover:bg-indigo-600 group-hover:text-white transition-all shadow-md shadow-indigo-500/20">
        ${m.no}
      </div>
      <!-- Content Card -->
      <div class="bg-slate-900/70 p-5 rounded-2xl border border-slate-800 hover:border-indigo-500/40 transition-all space-y-2">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-1">
          <h3 class="text-sm sm:text-base font-bold text-white flex items-center gap-2">
            <span>Tahap ${m.no}: ${m.stage}</span>
            <span class="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[10px] font-semibold">Selesai 100%</span>
          </h3>
          <span class="text-xs font-semibold px-2.5 py-1 rounded-lg bg-indigo-950 text-indigo-300 border border-indigo-800/50 self-start sm:self-auto">
            Durasi: ${m.duration}
          </span>
        </div>
        <div class="text-xs text-slate-300 flex items-center gap-2">
          <i data-lucide="calendar" class="w-3.5 h-3.5 text-sky-400"></i>
          <span>Waktu Pekerjaan: <strong>${m.startDate}</strong> s/d <strong>${m.endDate}</strong></span>
        </div>
        <p class="text-xs text-slate-400 pt-1 border-t border-slate-800/60">
          Tercatat dalam dokumen pembukuan lapangan tab Realisasi spreadsheet baris 406-414.
        </p>
      </div>
    </div>
  `).join('');

  if (window.lucide) lucide.createIcons();
}

// Quick filter when clicking category card
function filterByCategoryCode(catCode) {
  switchTab('transactions');
  const catSelect = document.getElementById('filter-category');
  if (catSelect) {
    catSelect.value = catCode;
    handleSearchFilter();
  }
}

// Filter and Search Handler for Transactions Table
function handleSearchFilter() {
  const search = (document.getElementById('search-input')?.value || '').toLowerCase().trim();
  const category = document.getElementById('filter-category')?.value || 'ALL';
  const source = document.getElementById('filter-source')?.value || 'ALL';
  const sort = document.getElementById('filter-sort')?.value || 'default';
  const perPageVal = document.getElementById('filter-per-page')?.value || '20';

  itemsPerPage = perPageVal === 'ALL' ? 999999 : parseInt(perPageVal, 10);
  currentPage = 1;

  const transactions = currentData.transactions || [];

  filteredTransactions = transactions.filter(t => {
    // Search match
    const matchSearch = !search || 
      (t.description && t.description.toLowerCase().includes(search)) ||
      (t.note && t.note.toLowerCase().includes(search)) ||
      (t.date && t.date.toLowerCase().includes(search));

    // Category match
    const matchCategory = category === 'ALL' || t.categoryCode === category;

    // Source match
    const matchSource = source === 'ALL' || t.source.toLowerCase() === source.toLowerCase();

    return matchSearch && matchCategory && matchSource;
  });

  // Sorting
  if (sort === 'price-desc') {
    filteredTransactions.sort((a, b) => (b.totalPrice || 0) - (a.totalPrice || 0));
  } else if (sort === 'price-asc') {
    filteredTransactions.sort((a, b) => (a.totalPrice || 0) - (b.totalPrice || 0));
  } else if (sort === 'date-desc') {
    filteredTransactions.sort((a, b) => parseDateToVal(b.date) - parseDateToVal(a.date));
  } else if (sort === 'date-asc') {
    filteredTransactions.sort((a, b) => parseDateToVal(a.date) - parseDateToVal(b.date));
  }

  renderTransactionsTable();
}

function parseDateToVal(dateStr) {
  if (!dateStr) return 0;
  const parts = dateStr.split('/');
  if (parts.length === 3) {
    const day = parseInt(parts[0], 10);
    const month = parseInt(parts[1], 10);
    const year = parseInt(parts[2], 10);
    return new Date(year, month - 1, day).getTime();
  }
  return 0;
}

// Reset Filters
function resetFilters() {
  if (document.getElementById('search-input')) document.getElementById('search-input').value = '';
  if (document.getElementById('filter-category')) document.getElementById('filter-category').value = 'ALL';
  if (document.getElementById('filter-source')) document.getElementById('filter-source').value = 'ALL';
  if (document.getElementById('filter-sort')) document.getElementById('filter-sort').value = 'default';
  if (document.getElementById('filter-per-page')) document.getElementById('filter-per-page').value = '20';
  handleSearchFilter();
  showToast('Filter pencarian telah direset');
}

// Render Transactions Table with Pagination
function renderTransactionsTable() {
  const tbody = document.getElementById('transaction-table-body');
  const countEl = document.getElementById('filter-count');
  const totalCountEl = document.getElementById('filter-total-count');
  const subtotalEl = document.getElementById('filter-subtotal');
  const pageInfoEl = document.getElementById('pagination-info');
  const pageControlsEl = document.getElementById('pagination-controls');

  const totalItems = filteredTransactions.length;
  const totalExpenseSum = filteredTransactions.reduce((acc, t) => acc + (t.totalPrice || 0), 0);

  if (countEl) countEl.textContent = formatNumber(totalItems);
  if (totalCountEl) totalCountEl.textContent = formatNumber(currentData.transactions?.length || 0);
  if (subtotalEl) subtotalEl.textContent = formatRupiah(totalExpenseSum);

  if (!tbody) return;

  if (totalItems === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="9" class="py-12 text-center text-slate-400">
          <i data-lucide="inbox" class="w-10 h-10 mx-auto text-slate-600 mb-2"></i>
          Tidak ada data transaksi yang cocok dengan kata kunci atau filter ini.
        </td>
      </tr>
    `;
    if (pageInfoEl) pageInfoEl.textContent = "Halaman 0 dari 0";
    if (pageControlsEl) pageControlsEl.innerHTML = "";
    if (window.lucide) lucide.createIcons();
    return;
  }

  // Calculate pagination slice
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  if (currentPage > totalPages) currentPage = totalPages;
  if (currentPage < 1) currentPage = 1;

  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = Math.min(startIndex + itemsPerPage, totalItems);
  const pageItems = filteredTransactions.slice(startIndex, endIndex);

  tbody.innerHTML = pageItems.map(item => {
    // Source color pill
    let sourcePill = '';
    const src = (item.source || '').toLowerCase();
    if (src.includes('iyan')) {
      sourcePill = '<span class="px-2 py-0.5 rounded-full bg-sky-950 text-sky-400 border border-sky-800/60 font-semibold text-[10px]">Iyan</span>';
    } else if (src.includes('rini')) {
      sourcePill = '<span class="px-2 py-0.5 rounded-full bg-rose-950 text-rose-400 border border-rose-800/60 font-semibold text-[10px]">Rini</span>';
    } else if (src.includes('emas')) {
      sourcePill = '<span class="px-2 py-0.5 rounded-full bg-amber-950 text-amber-400 border border-amber-800/60 font-semibold text-[10px]">Emas</span>';
    } else {
      sourcePill = `<span class="px-2 py-0.5 rounded-full bg-slate-800 text-slate-300 text-[10px]">${item.source || '-'}</span>`;
    }

    const catBadge = item.categoryCode ? `<span class="inline-block px-1.5 py-0.5 rounded text-[10px] font-bold bg-slate-800 text-slate-300 mr-1.5">${item.categoryCode}</span>` : '';
    const noteBadge = item.note ? `<div class="text-[11px] text-amber-400/90 italic flex items-center gap-1 mt-0.5"><i data-lucide="info" class="w-3 h-3 flex-shrink-0"></i>${item.note}</div>` : '';

    return `
      <tr class="hover:bg-slate-800/40 transition-colors">
        <td class="py-3 px-4 text-center text-slate-400 font-mono text-[11px]">${item.no}</td>
        <td class="py-3 px-4">
          <div class="font-medium text-slate-100 flex items-center">
            ${catBadge}
            <span>${item.description}</span>
          </div>
          ${noteBadge}
        </td>
        <td class="py-3 px-3 text-slate-300 whitespace-nowrap">${item.date || '-'}</td>
        <td class="py-3 px-3 whitespace-nowrap">${sourcePill}</td>
        <td class="py-3 px-3 text-right text-slate-300 font-mono whitespace-nowrap">
          ${item.volume ? formatNumber(item.volume) : '-'} <span class="text-slate-500 text-[10px]">${item.unit || ''}</span>
        </td>
        <td class="py-3 px-3 text-right text-slate-300 font-mono whitespace-nowrap">
          ${item.unitPrice ? formatRupiah(item.unitPrice) : '-'}
        </td>
        <td class="py-3 px-4 text-right font-bold text-white font-mono whitespace-nowrap">
          ${formatRupiah(item.totalPrice)}
        </td>
        <td class="py-3 px-4 text-right text-slate-400 font-mono text-[11px] whitespace-nowrap">
          ${item.balance ? formatRupiah(item.balance) : '-'}
        </td>
        <td class="py-3 px-4 text-slate-400 text-[11px]">
          ${item.note || '-'}
        </td>
      </tr>
    `;
  }).join('');

  // Pagination Info
  if (pageInfoEl) {
    pageInfoEl.innerHTML = `Menampilkan baris <strong>${startIndex + 1}</strong> - <strong>${endIndex}</strong> dari <strong>${formatNumber(totalItems)}</strong> data`;
  }

  // Pagination Controls
  if (pageControlsEl) {
    if (totalPages <= 1) {
      pageControlsEl.innerHTML = '';
    } else {
      let controlsHtml = `
        <button onclick="goToPage(${currentPage - 1})" ${currentPage === 1 ? 'disabled' : ''} class="px-2.5 py-1.5 rounded-lg border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700 disabled:opacity-30 disabled:cursor-not-allowed">
          <i data-lucide="chevron-left" class="w-3.5 h-3.5"></i>
        </button>
      `;

      // Page numbers (smart window)
      const startP = Math.max(1, currentPage - 2);
      const endP = Math.min(totalPages, currentPage + 2);

      for (let p = startP; p <= endP; p++) {
        const isActive = p === currentPage;
        controlsHtml += `
          <button onclick="goToPage(${p})" class="px-3 py-1 rounded-lg text-xs font-semibold ${isActive ? 'bg-sky-600 text-white shadow-sm' : 'border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700'}">
            ${p}
          </button>
        `;
      }

      controlsHtml += `
        <button onclick="goToPage(${currentPage + 1})" ${currentPage === totalPages ? 'disabled' : ''} class="px-2.5 py-1.5 rounded-lg border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700 disabled:opacity-30 disabled:cursor-not-allowed">
          <i data-lucide="chevron-right" class="w-3.5 h-3.5"></i>
        </button>
      `;

      pageControlsEl.innerHTML = controlsHtml;
    }
  }

  if (window.lucide) lucide.createIcons();
}

function goToPage(page) {
  currentPage = page;
  renderTransactionsTable();
  // Scroll table into view smoothly
  document.getElementById('search-input')?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

// Export Filtered Transactions to CSV
function exportFilteredCsv() {
  if (!filteredTransactions || filteredTransactions.length === 0) {
    alert("Tidak ada data untuk diekspor!");
    return;
  }

  const headers = ["No", "Kategori", "Uraian Pekerjaan", "Tanggal", "Sumber Dana", "Volume", "Satuan", "Harga Satuan", "Jumlah Harga", "Saldo Running", "Keterangan"];
  
  const csvRows = [headers.join(',')];

  filteredTransactions.forEach(t => {
    const row = [
      t.no,
      `"${(t.categoryName || '').replace(/"/g, '""')}"`,
      `"${(t.description || '').replace(/"/g, '""')}"`,
      `"${t.date || ''}"`,
      `"${t.source || ''}"`,
      t.volume || 0,
      `"${t.unit || ''}"`,
      t.unitPrice || 0,
      t.totalPrice || 0,
      t.balance || 0,
      `"${(t.note || '').replace(/"/g, '""')}"`
    ];
    csvRows.push(row.join(','));
  });

  const csvContent = "\uFEFF" + csvRows.join('\r\n');
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', `Realisasi_Rumah_PasarMinggu_${new Date().toISOString().slice(0, 10)}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);

  showToast(`Berhasil mengekspor ${filteredTransactions.length} baris transaksi ke CSV!`);
}

// Client-side CSV Parser for Real-time Google Sheet Sync
function parseGoogleSheetsCsv(csvText) {
  const lines = csvText.split(/\r\n|\n|\r/);
  const categories = [];
  const transactions = [];
  const milestones = [];
  let currentCategory = null;

  function parseCsvTokens(line) {
    const regex = /(?:^|,)(?:"([^"]*(?:""[^"]*)*)"|([^,]*))/g;
    let match;
    const fields = [];
    while ((match = regex.exec(line)) !== null) {
      if (match.index === regex.lastIndex) regex.lastIndex++;
      fields.push(match[1] ? match[1].replace(/""/g, '"') : match[2]);
    }
    return fields;
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line || !line.trim()) continue;

    const cols = parseCsvTokens(line);
    const c0 = (cols[0] || '').trim();
    const c1 = (cols[1] || '').trim();
    const c2 = (cols[2] || '').trim();
    const c3 = (cols[3] || '').trim();
    const c4 = (cols[4] || '').trim();
    const c5 = (cols[5] || '').trim();
    const c6 = (cols[6] || '').trim();
    const c7 = (cols[7] || '').trim();
    const c8 = (cols[8] || '').trim();
    const c9 = (cols[9] || '').trim();

    // Check Category Header A-I
    if (/^[A-I]$/.test(c0) && c1) {
      const cleanTotal = parseFloat(c7.replace(/\./g, '').replace(/,/g, '')) || 0;
      currentCategory = {
        code: c0,
        name: c1,
        total: cleanTotal,
        itemCount: 0
      };
      categories.push(currentCategory);
      continue;
    }

    // Check Row No
    const rowNo = parseInt(c0, 10);
    if (!isNaN(rowNo) && c1 && c2) {
      // Check if Milestone
      if (c1.includes('=') && c1.includes('2025')) {
        const parts = c1.split('=');
        const range = parts[0].trim();
        const stage = parts[1] ? parts[1].trim() : c1;
        const dateParts = range.split('-');
        milestones.push({
          no: rowNo,
          startDate: dateParts[0] ? dateParts[0].trim() : '',
          endDate: dateParts[1] ? dateParts[1].trim() : '',
          stage: stage,
          duration: c2
        });
        continue;
      }

      // Regular construction item
      const vol = parseFloat(c4.replace(/,/g, '')) || 0;
      const unitPrice = parseFloat(c6.replace(/\./g, '').replace(/,/g, '')) || 0;
      const totPrice = parseFloat(c7.replace(/\./g, '').replace(/,/g, '')) || 0;
      const bal = parseFloat(c8.replace(/\./g, '').replace(/,/g, '')) || 0;

      if (currentCategory) currentCategory.itemCount++;

      transactions.push({
        id: `${currentCategory ? currentCategory.code : ''}-${rowNo}`,
        no: rowNo,
        categoryCode: currentCategory ? currentCategory.code : '',
        categoryName: currentCategory ? currentCategory.name : '',
        description: c1,
        date: c2,
        source: c3,
        volume: vol,
        unit: c5,
        unitPrice: unitPrice,
        totalPrice: totPrice,
        balance: bal,
        note: c9
      });
    }
  }

  return { categories, transactions, milestones };
}

// Live Sync with Google Sheets
async function syncGoogleSheets() {
  const syncBtn = document.getElementById('btn-sync');
  const syncIcon = document.getElementById('sync-icon');
  const lastUpdatedEl = document.getElementById('last-updated-text');
  
  const sheetUrl = "https://docs.google.com/spreadsheets/d/10NPojs4QgHb7g75RFPtf7C3kZDmpK7GPeFaEVcJNr30/export?format=csv&gid=1704651089";

  try {
    if (syncIcon) syncIcon.classList.add('animate-spin');
    if (syncBtn) syncBtn.classList.add('opacity-70');

    const res = await fetch(sheetUrl);
    if (!res.ok) throw new Error(`HTTP ${res.status}: Gagal mengunduh spreadsheet`);
    const csvText = await res.text();

    const parsed = parseGoogleSheetsCsv(csvText);

    if (parsed.categories.length > 0 && parsed.transactions.length > 0) {
      currentData.categories = parsed.categories;
      currentData.transactions = parsed.transactions;
      if (parsed.milestones.length > 0) currentData.milestones = parsed.milestones;

      // Recalculate funding
      const newTotalExpense = parsed.transactions.reduce((acc, t) => acc + (t.totalPrice || 0), 0);
      currentData.funding.totalPengeluaran = newTotalExpense;
      currentData.funding.saldoAkhir = currentData.funding.saldoAwal - newTotalExpense;

      // Update UI
      updateUI();
      if (lastUpdatedEl) {
        lastUpdatedEl.textContent = `Sinkronisasi Live Berhasil: ${new Date().toLocaleTimeString('id-ID')} WIB`;
      }
      showToast(`Data berhasil disinkronkan langsung dari Google Sheet! (${parsed.transactions.length} baris)`);
    } else {
      throw new Error("Format CSV tidak dikenali.");
    }
  } catch (err) {
    console.warn("Sinkronisasi langsung Google Sheet terbatas oleh browser CORS atau offline, menggunakan cache lokal:", err);
    showToast("Menggunakan data tersimpan (Google Sheet sedang offline atau dibatasi oleh browser).");
  } finally {
    if (syncIcon) syncIcon.classList.remove('animate-spin');
    if (syncBtn) syncBtn.classList.remove('opacity-70');
  }
}

// Refresh all UI components
function updateUI() {
  // Update Header Title
  const projTitle = document.getElementById('proj-title');
  if (projTitle) projTitle.textContent = currentData.project?.title || "Pembangunan Rumah Pasar Minggu";

  // Update Header & KPI
  const kpiExpense = document.getElementById('kpi-total-expense');
  const kpiBudget = document.getElementById('kpi-initial-budget');
  const kpiBalance = document.getElementById('kpi-final-balance');
  const kpiItemCount = document.getElementById('kpi-item-count');
  const tabTxCount = document.getElementById('tab-tx-count');

  if (kpiExpense) kpiExpense.textContent = formatRupiah(currentData.funding?.totalPengeluaran || 190693643);
  if (kpiBudget) kpiBudget.textContent = formatRupiah(currentData.funding?.saldoAwal || 114000000);
  if (kpiBalance) kpiBalance.textContent = formatRupiah(currentData.funding?.saldoAkhir || -76663643);
  if (kpiItemCount) kpiItemCount.textContent = `${currentData.transactions?.length || 363} Rincian Item`;
  if (tabTxCount) tabTxCount.textContent = currentData.transactions?.length || 363;

  // Render Charts & Cards
  initCharts();
  renderCategoryCards();
  renderMiniMilestones();
  renderFullTimeline();

  // Reset & Re-render Transactions
  handleSearchFilter();
}

// Document Ready Initialization
document.addEventListener('DOMContentLoaded', () => {
  // Render Lucide Icons
  if (window.lucide) lucide.createIcons();

  // Initial UI Render
  updateUI();
});
