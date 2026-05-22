import PptxGenJS from 'pptxgenjs'

// Colour palette matching the app
const C = {
  bg:      '0F0A1E',
  card:    '1A1033',
  card2:   '221844',
  purple:  '7C3AED',
  purpleL: 'A78BFA',
  blue:    '4F46E5',
  blueL:   '60A5FA',
  white:   'FFFFFF',
  gray:    '9CA3AF',
  red:     'EF4444',
  amber:   'F59E0B',
  green:   '10B981',
  dark:    '2A1A50',
}

// ── helpers ────────────────────────────────────────────────────────────────

function blob(sld, x, y, w, h, color, transparency = 82) {
  sld.addShape(sld._slideRId ? PptxGenJS.ShapeType?.ellipse ?? 'ellipse' : 'ellipse', {
    x, y, w, h,
    fill: { color, transparency },
    line: { color, transparency },
  })
}

function rect(sld, x, y, w, h, color, alpha = 0) {
  sld.addShape('rect', {
    x, y, w, h,
    fill: { color, transparency: alpha },
    line: { color, transparency: alpha },
  })
}

function roundRect(sld, x, y, w, h, fillColor, strokeColor, radius = 0.1, fillAlpha = 0, strokeAlpha = 40) {
  sld.addShape('roundRect', {
    x, y, w, h,
    fill: { color: fillColor, transparency: fillAlpha },
    line: { color: strokeColor, transparency: strokeAlpha },
    rectRadius: radius,
  })
}

function txt(sld, text, x, y, w, h, opts = {}) {
  sld.addText(text, {
    x, y, w, h,
    fontFace: 'Calibri',
    color: C.white,
    valign: 'middle',
    wrap: true,
    ...opts,
  })
}

// ── Title slide ────────────────────────────────────────────────────────────

function slideTitlePage(prs, title, subtitle, interest, entities) {
  const sld = prs.addSlide()
  sld.background = { color: C.bg }

  sld.addShape('ellipse', { x: 7.2, y: -0.6, w: 2.8, h: 2.8, fill: { color: C.purple, transparency: 75 }, line: { color: C.purple, transparency: 75 } })
  sld.addShape('ellipse', { x: -0.4, y: 4.2, w: 2, h: 2, fill: { color: C.blue, transparency: 80 }, line: { color: C.blue, transparency: 80 } })

  rect(sld, 0.5, 1.4, 1.2, 0.06, C.purpleL)

  txt(sld, 'ПЕРСОНАЛЬНЫЙ РАЗБОР ПРОБЕЛОВ', 0.5, 1.1, 9, 0.3, {
    fontSize: 10, bold: true, color: C.purpleL, charSpacing: 2,
  })
  txt(sld, title, 0.5, 1.65, 8.5, 1.6, { fontSize: 34, bold: true, breakLine: true })
  txt(sld, subtitle, 0.5, 3.3, 8, 0.5, { fontSize: 15, color: C.gray })

  // Entity tags
  const tags = (entities || []).slice(0, 4)
  tags.forEach((tag, i) => {
    sld.addShape('roundRect', {
      x: 0.5 + i * 2.2, y: 4.0, w: 2.0, h: 0.34,
      fill: { color: C.purple, transparency: 60 },
      line: { color: C.purpleL, transparency: 35 },
      rectRadius: 0.1,
    })
    txt(sld, tag, 0.5 + i * 2.2, 4.0, 2.0, 0.34, {
      fontSize: 10, color: C.purpleL, align: 'center',
    })
  })
}

// ── Overview slide ─────────────────────────────────────────────────────────

function slideOverview(prs, slides, interest, style) {
  const sld = prs.addSlide()
  sld.background = { color: C.bg }

  sld.addShape('ellipse', { x: 7.5, y: -0.3, w: 2.2, h: 2.2, fill: { color: C.blue, transparency: 82 }, line: { color: C.blue, transparency: 82 } })

  txt(sld, 'СОДЕРЖАНИЕ', 0.5, 0.35, 9, 0.3, { fontSize: 10, bold: true, color: C.purpleL, charSpacing: 2 })
  txt(sld, 'Темы для проработки', 0.5, 0.7, 8, 0.55, { fontSize: 26, bold: true })

  sld.addShape('roundRect', { x: 0.5, y: 1.32, w: 3.0, h: 0.34, fill: { color: C.purple, transparency: 55 }, line: { color: C.purpleL, transparency: 30 }, rectRadius: 0.1 })
  txt(sld, `⭐ ${interest}  •  ${style}`, 0.5, 1.32, 3.0, 0.34, { fontSize: 10, color: C.purpleL, align: 'center' })

  const statusColor = { missing: C.red, incomplete: C.amber, concept: C.blueL }
  const statusLabel = { missing: '❌ Пропущена', incomplete: '⚠️ Не понята', concept: '💡 Концепция' }

  slides.forEach((s, i) => {
    const y = 1.88 + i * 0.54
    const col = statusColor[s.status_key] || C.purpleL

    sld.addShape('roundRect', { x: 0.5, y, w: 8.8, h: 0.44, fill: { color: C.card2, transparency: 0 }, line: { color: col, transparency: 55 }, rectRadius: 0.08 })
    txt(sld, `${i + 1}`, 0.6, y, 0.38, 0.44, { fontSize: 12, bold: true, color: col, align: 'center' })
    txt(sld, s.title, 1.05, y, 5.8, 0.44, { fontSize: 13 })
    txt(sld, statusLabel[s.status_key] || s.status || '', 6.9, y, 2.3, 0.44, { fontSize: 10, color: col, align: 'right' })
  })
}

// ── Topic slide ────────────────────────────────────────────────────────────

function slideTopic(prs, slide, num, total) {
  const sld = prs.addSlide()
  sld.background = { color: C.bg }

  // Header bar
  rect(sld, 0, 0, 10, 1.04, C.card)
  rect(sld, 0, 0, 0.12, 1.04, C.purple)

  const statusColor = slide.status?.includes('пропущ') ? C.red : C.amber
  sld.addShape('roundRect', { x: 0.25, y: 0.14, w: 2.0, h: 0.3, fill: { color: statusColor, transparency: 72 }, line: { color: statusColor, transparency: 40 }, rectRadius: 0.08 })
  txt(sld, slide.status || 'слабая тема', 0.25, 0.14, 2.0, 0.3, { fontSize: 9, bold: true, color: statusColor, align: 'center' })
  txt(sld, `${num} / ${total}`, 8.5, 0.18, 1.4, 0.3, { fontSize: 10, color: C.gray, align: 'right' })
  txt(sld, slide.title, 0.25, 0.48, 9.3, 0.52, { fontSize: 22, bold: true, valign: 'middle' })

  // Has image → two-column layout, else single-column
  const hasImage = !!slide.image_base64
  const textW = hasImage ? 5.7 : 9.5

  // Explanation card
  sld.addShape('roundRect', { x: 0.25, y: 1.1, w: textW, h: 1.5, fill: { color: C.card2, transparency: 0 }, line: { color: C.purple, transparency: 58 }, rectRadius: 0.1 })
  txt(sld, '📖  Объяснение', 0.45, 1.15, textW - 0.4, 0.26, { fontSize: 10, bold: true, color: C.purpleL })
  txt(sld, slide.explanation || '', 0.45, 1.42, textW - 0.4, 1.12, { fontSize: 12, valign: 'top' })

  // Key points (right column or below explanation)
  const kpX = hasImage ? 0.25 : 0.25
  const kpY = hasImage ? 2.72 : 2.7
  const kpW = hasImage ? 5.7 : 9.5
  sld.addShape('roundRect', { x: kpX, y: kpY, w: kpW, h: 1.0, fill: { color: C.card2, transparency: 0 }, line: { color: C.blue, transparency: 55 }, rectRadius: 0.1 })
  txt(sld, '⚡  Ключевые факты', kpX + 0.2, kpY + 0.06, kpW - 0.4, 0.26, { fontSize: 10, bold: true, color: C.blueL })
  ;(slide.key_points || []).slice(0, 3).forEach((pt, i) => {
    txt(sld, `• ${pt}`, kpX + 0.2, kpY + 0.3 + i * 0.24, kpW - 0.4, 0.23, { fontSize: 11, valign: 'top' })
  })

  // Image (right column)
  if (hasImage) {
    try {
      sld.addImage({
        data: `image/${slide.image_ext || 'jpg'};base64,${slide.image_base64}`,
        x: 6.1, y: 1.1, w: 3.65, h: 2.62,
        sizing: { type: 'contain', w: 3.65, h: 2.62 },
      })
    } catch (_) { /* image might fail, continue */ }

    // Entity label under image
    sld.addShape('roundRect', { x: 6.1, y: 3.76, w: 3.65, h: 0.28, fill: { color: C.purple, transparency: 65 }, line: { color: C.purpleL, transparency: 35 }, rectRadius: 0.06 })
    txt(sld, slide.entity || '', 6.1, 3.76, 3.65, 0.28, { fontSize: 9, color: C.purpleL, align: 'center' })
  }

  // Interest example (full width at bottom)
  const exY = hasImage ? 3.84 : 3.8
  const exH = 0.9
  sld.addShape('roundRect', { x: 0.25, y: exY, w: 9.5, h: exH, fill: { color: C.dark, transparency: 0 }, line: { color: C.purple, transparency: 35 }, rectRadius: 0.1 })
  txt(sld, '⭐  Пример из твоих интересов', 0.45, exY + 0.06, 9, 0.24, { fontSize: 10, bold: true, color: C.purpleL })
  txt(sld, slide.interest_example || '', 0.45, exY + 0.3, 9, exH - 0.36, { fontSize: 12, valign: 'top' })

  // Remember footer
  if (slide.remember) {
    sld.addShape('roundRect', { x: 0.25, y: 4.82, w: 9.5, h: 0.42, fill: { color: C.green, transparency: 78 }, line: { color: C.green, transparency: 50 }, rectRadius: 0.08 })
    txt(sld, `💡  ${slide.remember}`, 0.45, 4.82, 9, 0.42, { fontSize: 12, bold: true, color: C.white, valign: 'middle' })
  }
}

// ── Final slide ────────────────────────────────────────────────────────────

function slideFinal(prs, interest, entities) {
  const sld = prs.addSlide()
  sld.background = { color: C.bg }

  sld.addShape('ellipse', { x: 3.5, y: 0.5, w: 3, h: 3, fill: { color: C.purple, transparency: 88 }, line: { color: C.purple, transparency: 88 } })

  txt(sld, '✅', 4.3, 0.9, 1.4, 1.2, { fontSize: 48, align: 'center', valign: 'top' })
  txt(sld, 'Продолжай в том же духе!', 1, 2.1, 8, 0.7, { fontSize: 28, bold: true, align: 'center' })
  txt(sld, `Используй примеры из ${interest} — это твой секретный инструмент запоминания`, 1.5, 2.85, 7, 0.55, { fontSize: 14, color: C.gray, align: 'center' })

  const tags = (entities || []).slice(0, 4)
  const tagW = 9 / Math.max(tags.length, 1)
  tags.forEach((t, i) => {
    sld.addShape('roundRect', { x: 0.5 + i * tagW, y: 3.58, w: tagW - 0.1, h: 0.34, fill: { color: C.purple, transparency: 65 }, line: { color: C.purpleL, transparency: 35 }, rectRadius: 0.1 })
    txt(sld, t, 0.5 + i * tagW, 3.58, tagW - 0.1, 0.34, { fontSize: 10, color: C.purpleL, align: 'center' })
  })

  sld.addShape('roundRect', { x: 2.5, y: 4.18, w: 5, h: 0.56, fill: { color: C.purple, transparency: 45 }, line: { color: C.purpleL, transparency: 20 }, rectRadius: 0.15 })
  txt(sld, '🤖 Сгенерировано Sabaq Coach', 2.5, 4.18, 5, 0.56, { fontSize: 13, color: C.purpleL, align: 'center' })
}

// ── Main export ────────────────────────────────────────────────────────────

export async function buildPptx(slidesData, interest, lectureTitle, entities = [], style = '') {
  const prs = new PptxGenJS()
  prs.layout  = 'LAYOUT_WIDE'
  prs.author  = 'Sabaq Coach'
  prs.title   = lectureTitle || 'Разбор слабых тем'
  prs.subject = 'Персональный разбор пробелов'

  const enriched = slidesData.map(s => ({
    ...s,
    status_key: s.status?.includes('пропущ') ? 'missing'
               : s.status?.includes('понят')  ? 'incomplete'
               : 'concept',
  }))

  slideTitlePage(prs, lectureTitle || 'Разбор слабых тем', `${style || interest} • ${entities.slice(0,3).join(', ')}`, interest, entities)
  slideOverview(prs, enriched, interest, style)
  enriched.forEach((s, i) => slideTopic(prs, s, i + 1, enriched.length))
  slideFinal(prs, interest, entities)

  const filename = `разбор_пробелов_${Date.now()}.pptx`
  await prs.writeFile({ fileName: filename })
  return filename
}
