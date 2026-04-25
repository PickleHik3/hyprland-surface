pragma Singleton
import Quickshell

Singleton {
    id: root

    function bestGridForRegion(count, regionW, regionH, gap, targetAspect, preferredCols) {
        var best = {
            cols: 1,
            rows: 1,
            score: -1
        }

        for (var cols = 1; cols <= count; cols++) {
            var rows = Math.ceil(count / cols)
            var availW = regionW - gap * (cols - 1)
            var availH = regionH - gap * (rows - 1)
            if (availW <= 0 || availH <= 0)
                continue

            var cellW = availW / cols
            var cellH = availH / rows
            var aspectPenalty = Math.abs((cellW / Math.max(1, cellH)) - targetAspect)
            var sizeScore = Math.min(cellW / targetAspect, cellH)
            var columnPenalty = preferredCols > 0 ? Math.abs(cols - preferredCols) * 42 : 0
            var rowPenalty = Math.abs(rows - cols) * 5
            var score = sizeScore - (aspectPenalty * 120) - columnPenalty - rowPenalty
            if (score > best.score) {
                best.cols = cols
                best.rows = rows
                best.score = score
            }
        }

        return best
    }

    function layoutGrid(items, regionX, regionY, regionW, regionH, gap, targetAspect, preferredCols) {
        var output = []
        if (!items || items.length === 0)
            return output

        var grid = bestGridForRegion(items.length, regionW, regionH, gap, targetAspect, preferredCols)
        var cols = grid.cols
        var rows = grid.rows

        var availW = regionW - gap * (cols - 1)
        var availH = regionH - gap * (rows - 1)
        var maxCellW = availW / cols
        var maxCellH = availH / rows
        var cardW = maxCellW
        var cardH = cardW / targetAspect

        if (cardH > maxCellH) {
            cardH = maxCellH
            cardW = cardH * targetAspect
        }

        var totalGridHeight = (rows * cardH) + (Math.max(0, rows - 1) * gap)
        var gridStartY = regionY + Math.max(0, (regionH - totalGridHeight) / 2)

        for (var r = 0; r < rows; r++) {
            var startIndex = r * cols
            var endIndex = Math.min(startIndex + cols, items.length)
            if (startIndex >= items.length)
                break

            var rowItems = []
            for (var i = startIndex; i < endIndex; i++)
                rowItems.push(items[i])

            var totalRowWidth = (rowItems.length * cardW) + (Math.max(0, rowItems.length - 1) * gap)
            var currentX = regionX + (regionW - totalRowWidth) / 2
            var rowY = gridStartY + r * (cardH + gap)
            for (var k = 0; k < rowItems.length; k++) {
                var item = rowItems[k]
                output.push({
                    win: item.win,
                    x: currentX,
                    y: rowY,
                    width: cardW,
                    height: cardH,
                    workspaceId: item.workspaceId
                })
                currentX += cardW + gap
            }
        }

        return output
    }

    function doLayout(windowList, outerWidth, outerHeight) {
        var N = windowList.length
        if (N === 0) return []
        if (outerWidth <= 0 || outerHeight <= 0) return []

        var isPortrait = outerHeight > outerWidth
        var gap = Math.round(Math.min(outerWidth * (isPortrait ? 0.016 : 0.012), outerHeight * (isPortrait ? 0.015 : 0.013)))
        var usableW = outerWidth * (isPortrait ? 0.92 : 0.94)
        var usableH = outerHeight * (isPortrait ? 0.9 : 0.94)
        var targetAspect = isPortrait ? 0.84 : 1.08
        var preferredCols

        if (isPortrait) {
            preferredCols = N <= 2 ? 1 : 2
        } else {
            if (N <= 1)
                preferredCols = 1
            else if (N <= 4)
                preferredCols = 2
            else if (N <= 8)
                preferredCols = 3
            else
                preferredCols = 4
        }

        var sorted = windowList.slice(0)
        sorted.sort(function(a, b) {
            var aws = Number(a.workspaceId || 1)
            var bws = Number(b.workspaceId || 1)
            if (aws !== bws)
                return aws - bws
            var ai = Number(a.originalIndex || 0)
            var bi = Number(b.originalIndex || 0)
            return ai - bi
        })

        return layoutGrid(
            sorted,
            (outerWidth - usableW) / 2,
            (outerHeight - usableH) / 2,
            usableW,
            usableH,
            gap,
            targetAspect,
            preferredCols
        )
    }
}
