pragma Singleton
import Quickshell

Singleton {
    id: root

    function bestGridForRegion(items, regionW, regionH, gap, isPortrait, targetAspect) {
        var count = items.length
        var best = {
            cols: 1,
            rows: 1,
            score: 0
        }

        for (var cols = 1; cols <= count; cols++) {
            var rows = Math.ceil(count / cols)
            var availW = regionW - gap * (cols - 1)
            var availH = regionH - gap * (rows - 1)
            if (availW <= 0 || availH <= 0)
                continue

            var cellW = availW / cols
            var cellH = availH / rows
            var scaleW = cellW / targetAspect
            var scaleH = cellH / 1.0
            var score = Math.min(scaleW, scaleH)
            if (score > best.score) {
                best.cols = cols
                best.rows = rows
                best.score = score
            }
        }

        return best
    }

    function layoutWorkspaceGroup(items, regionX, regionY, regionW, regionH, gap, isPortrait, targetAspect) {
        var output = []
        if (!items || items.length === 0)
            return output

        var grid = bestGridForRegion(items, regionW, regionH, gap, isPortrait, targetAspect)
        var cols = grid.cols
        var rows = grid.rows

        var availW = regionW - gap * (cols - 1)
        var availH = regionH - gap * (rows - 1)
        var maxCellW = availW / cols
        var maxCellH = availH / rows

        for (var r = 0; r < rows; r++) {
            var startIndex = r * cols
            var endIndex = Math.min(startIndex + cols, items.length)
            if (startIndex >= items.length)
                break

            var rowItems = []
            var totalRowWidth = 0
            for (var i = startIndex; i < endIndex; i++) {
                var item = items[i]
                var w0 = (item.width && item.width > 0) ? item.width : 100
                var h0 = (item.height && item.height > 0) ? item.height : 100
                var scale = Math.min(maxCellW / w0, maxCellH / h0)
                var thumbW = w0 * scale
                var thumbH = h0 * scale

                rowItems.push({
                    item: item,
                    width: thumbW,
                    height: thumbH
                })
                totalRowWidth += thumbW
            }

            if (rowItems.length > 1)
                totalRowWidth += (rowItems.length - 1) * gap

            var currentX = regionX + (regionW - totalRowWidth) / 2
            var rowY = regionY + r * (maxCellH + gap)
            for (var k = 0; k < rowItems.length; k++) {
                var rItem = rowItems[k]
                var currentY = rowY + (maxCellH - rItem.height) / 2
                output.push({
                    win: rItem.item.win,
                    x: currentX,
                    y: currentY,
                    width: rItem.width,
                    height: rItem.height,
                    workspaceId: rItem.item.workspaceId
                })
                currentX += rItem.width + gap
            }
        }

        return output
    }

    function doLayout(windowList, outerWidth, outerHeight) {
        var N = windowList.length
        if (N === 0) return []
        if (outerWidth <= 0 || outerHeight <= 0) return []

        var isPortrait = outerHeight > outerWidth
        var gap = Math.min(outerWidth * (isPortrait ? 0.022 : 0.03), outerHeight * (isPortrait ? 0.022 : 0.03))

        // --- 0. DEFINIZIONE AREA SICURA (SCALATA) ---
        // Riduciamo l'area di calcolo al 90% per lasciare spazio alle animazioni hover
        var contentScale = isPortrait ? 0.94 : 0.9
        var usableW = outerWidth * contentScale
        var usableH = outerHeight * contentScale

        // Workspace-aware packing: each workspace gets a horizontal band.
        // This keeps left-to-right ordering by workspace ID.
        var TARGET_ASPECT = isPortrait ? (10.0 / 16.0) : (16.0 / 9.0)
        var groups = {}
        var workspaceIds = []
        for (var wi = 0; wi < N; wi++) {
            var ws = Number(windowList[wi].workspaceId)
            if (!isFinite(ws) || ws < 1)
                ws = 1
            if (!groups[ws]) {
                groups[ws] = []
                workspaceIds.push(ws)
            }
            groups[ws].push(windowList[wi])
        }
        workspaceIds.sort(function(a, b) { return a - b })

        var bandCount = workspaceIds.length
        var totalBandGap = gap * Math.max(0, bandCount - 1)
        var bandW = (usableW - totalBandGap) / Math.max(1, bandCount)
        var startX = (outerWidth - usableW) / 2
        var startY = (outerHeight - usableH) / 2

        var result = []
        for (var bi = 0; bi < workspaceIds.length; bi++) {
            var workspaceId = workspaceIds[bi]
            var regionX = startX + bi * (bandW + gap)
            var groupResult = layoutWorkspaceGroup(
                groups[workspaceId],
                regionX,
                startY,
                bandW,
                usableH,
                gap,
                isPortrait,
                TARGET_ASPECT
            )
            for (var gi = 0; gi < groupResult.length; gi++)
                result.push(groupResult[gi])
        }

        return result
    }
}
