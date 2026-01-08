(function() {
    var crossdoc = {}

    // simple hash function to make unique string ids
    function hashCode(s) {
        return (s.split("").reduce(function(a,b){a=((a<<5)-a)+b.charCodeAt(0);return a&a},0) >>> 0).toString(16);
    }

    // processes a url to make sure it's absolute
    function processUrl(url) {
        if (!url)
            return null
        if (url.indexOf('http') === 0 || url.indexOf('data:') === 0) {
            // do nothing, this is fine
        }
        else if (url.indexOf('/') === 0) { // treat it as absolute path
            url = window.location.origin + url
        }
        else { // treat as relative path
            var link = document.createElement("a")
            link.href = url
            url = link.href
        }
        return url
    }

    // jQuery's hasClass implementation
    function hasClass(element, className) {
        className = " " + className + " "
        return (" " + element.className + " ").replace(/[\n\t]/g, " ").indexOf(className) > -1
    }

    // parses a string containing a pixel value into a float
    function parsePxString(s) {
        return parseFloat(s.replace('px', ''))
    }

    // parses an arbitrary color string into an 8 character hex color
    function parseColorString(s) {
        function twoChars(s) {
            if (s.length === 1)
                return '0' + s
            return s
        }
        function decToHex(vals) {
            return vals.map(function(val) {return twoChars(parseInt(val).toString(16))})
        }
        s = s.trim()
        var comps
        if (s.indexOf('rgba(') === 0) {
            comps = s.replace('rgba(', '').replace(')', '').split(', ')
            return '#' + decToHex(comps.slice(0,3)).join('') + (parseFloat(comps[3]) * 255 | 1 << 8).toString(16).slice(1)
        }
        else if (s.indexOf('rgb(') === 0) {
            comps = s.replace('rgb(', '').replace(')', '').split(', ')
            return '#' + decToHex(comps).join('') + 'ff'
        }
        else {
            return s
        }
    }

    // returns true if a color string has a non-zero alpha
    function isVisibleColor(color) {
        if (color === 'transparent')
            return false
        else if (color.length === 7)
            return true
        else if (color.length === 9) {
            return color.substring(7)!=='00'
        }
        else
            throw "Invalid color string: " + color
    }

    // parses the border styles out into a border object
    function parseBorder(style) {
        function parseBorderSide(side) {
            var comps = side.split(' ')
            var border = {}
            border.width = parsePxString(comps[0])
            if (border.width === 0)
                return null
            border.style = comps[1]
            border.color = parseColorString(comps.slice(2, comps.length).join(' '))
            return border
        }
        var border = {}
        var b = parseBorderSide(style.borderTop)
        if (b)
            border.top = b
        b = parseBorderSide(style.borderRight)
        if (b)
            border.right = b
        b = parseBorderSide(style.borderBottom)
        if (b)
            border.bottom = b
        b = parseBorderSide(style.borderLeft)
        if (b)
            border.left = b
        return border
    }

    // parses the background properties
    function parseBackground(style) {
        return {
            attachment: style.backgroundAttachment,
            color: parseColorString(style.backgroundColor),
            image: style.backgroundImage==='none' ? null : style.backgroundImage,
            position: style.backgroundPosition,
            repeat: style.backgroundRepeat
        }
    }

    // Adds general style-related attributes to the object
    function parseStyle(node, obj, style) {
        if (style.borderWidth.length > 0 && parseFloat(style.borderWidth.replace(/px\s*/g,'')) > 0) {
            obj.border = parseBorder(style)
        }

        var background = parseBackground(style)
        if (isVisibleColor(background.color) || background.image) {
            obj.background = background
        }

        var padding = {
            top: parsePxString(style.paddingTop),
            right: parsePxString(style.paddingRight),
            bottom: parsePxString(style.paddingBottom),
            left: parsePxString(style.paddingLeft)
        }
        if (padding.top !==0 || padding.right !== 0 || padding.left !== 0 || padding.bottom !== 0) {
            obj.padding = padding
        }
    }

    // Add text-specific style attributes to the object
    function parseTextStyle(node, obj, style) {
        obj.font = {
            size: parsePxString(style.fontSize),
            weight: style.fontWeight,
            family: style.fontFamily,
            decoration: style.textDecoration,
            style: style.fontStyle,
            color: parseColorString(style.color),
            align: style.textAlign==='start' ? 'left' : style.textAlign,
            transform: style.textTransform
        }
        if (style.lineHeight==='normal')
            obj.font.lineHeight = 1.2 * obj.font.size
        else
            obj.font.lineHeight = parsePxString(style.lineHeight)
        if (style.letterSpacing!=='normal')
            obj.font.letterSpacing = parsePxString(style.letterSpacing)
    }

    // Parse an individual child node
    function parseChild(doc, childNode, parentRect) {
        switch (childNode.nodeType) {
            case Node.ELEMENT_NODE:
                return parseNode(doc, childNode, parentRect)
            case Node.TEXT_NODE:
                var text = childNode.data.trim()
                if (text.length > 0) {
                    return [{ tag: 'TEXT', text: text }]
                }
                return []
            default:
                console.log("Don't know what to do with node type " + childNode.nodeType)
                console.log(childNode)
                return []
        }
    }

    // Recursively parses a node and its children
    function parseNode(doc, node, parentRect) {
        var i
        var obj = {
            tag: node.tagName
        }
        if (isTagBlacklisted(obj.tag))
            return []

        var style = window.getComputedStyle(node)

        parseStyle(node, obj, style)

        // don't bother parsing display: none elements
        if (style.display === 'none')
            return []

        // parse the children
        var childNodes = Array.from(node.childNodes)
        if (node.shadowRoot) {
            childNodes = childNodes.concat(Array.from(node.shadowRoot.childNodes))
        }

        var nodeRect = style.display === 'contents' ? parentRect : node.getBoundingClientRect()
        var offset = {
          x: nodeRect.left - parentRect.left,
          y: nodeRect.top - parentRect.top
        }
        var children = childNodes.flatMap(childNode => parseChild(doc, childNode, nodeRect))

        // display == contents means render this node's children directly into its parent with no formatting from itself
        if (style.display === 'contents') {
            return children
        }

        // we only need box size for non-inline elements
        var display = style.display
        var nodeHeight = nodeRect.height
        for (i = 0; i < node.childNodes.length; i++) {
            var child = node.childNodes[i]
            // inline elements with line breaks are inherently blocks
            if (child.tagName === 'BR') {
                display = 'block'
                nodeHeight *= 1.3 // hack to ensure that text actually renders
                break;
            }
        }
        if (display !== 'inline' || node.tagName === 'IMG') {
            obj.box = {
                x: offset.x,
                y: offset.y,
                width: nodeRect.width,
                height: nodeHeight
            }
        }

        var hasText = children.some(child => child.tag === 'TEXT')

        // run the tag-specific parser, if one exists
        if (tagParsers.hasOwnProperty(obj.tag)) {
            tagParsers[obj.tag](doc, node, obj, style)
        } else if (node.constructor && customElements.getName(node.constructor)) {
            // this is a custom tag, treat it as a div
            obj.tag = 'DIV'
        }

        // flatten single text nodes
        if (obj.tag === 'FONT' && children.length === 1 && children[0].tag === 'TEXT') {
            obj.tag = 'TEXT'
            obj.text = children[0].text
            hasText = true
        }
        else if (children.length === 1 && children[0].tag==='TEXT') {
            obj.text = children[0].text
            hasText = true
        }
        else if (children.length > 0) {
            obj.children = children
        }
        // parse text styles
        if (hasText || obj.inputValue)
            parseTextStyle(node, obj, style)

        return [obj]
    }

    function parsePage(doc, pageNode) {
        var node = null
        var i
        for (i in pageNode.childNodes) {
            var n = pageNode.childNodes[i]
            if (n.className && n.className.indexOf('page-content') > -1) {
                node = n
                break
            }
        }
        if (node === null)
            throw "Each page must have exactly one child node with class page-content"
        var page = {
            children: []
        }

        var style = window.getComputedStyle(node)
        page.padding = {
            top: parsePxString(style.paddingTop),
            right: parsePxString(style.paddingRight),
            bottom: parsePxString(style.paddingBottom),
            left: parsePxString(style.paddingLeft)
        }

        // parse the children
        var pageRect = node.getBoundingClientRect()
        page.children = Array.from(node.childNodes).flatMap(childNode => parseChild(doc, childNode, pageRect))

        return page
    }

    var tagParsers = {}

    tagParsers.IMG = function(doc, node, obj, style) {
        obj.src = processUrl(node.getAttribute('src'))
        if (obj.src) {
            obj.hash = hashCode(obj.src)
            doc.images[obj.hash] = {src: obj.src, hash: obj.hash}
        }
    }

    tagParsers.INPUT = function(doc, node, obj, style) {
        obj.inputType = node.getAttribute('type')
        obj.inputValue = node.value
    }

    tagParsers.TEXTAREA = function(doc, node, obj, style) {
        obj.inputType = 'text'
        obj.inputValue = node.value
    }

    tagParsers.UL = function(doc, node, obj, style) {
        obj.listStyle = style.listStyleType
    }
    tagParsers.OL = function(doc, node, obj, style) {
        obj.listStyle = style.listStyleType
        if (node.start)
            obj.start = node.start
    }

    // don't parse these tags, they aren't a part of the visible DOM
    var tagBlacklist = ['OPTION', 'SCRIPT']

    function isTagBlacklisted(tag) {
        return tagBlacklist.indexOf(tag) > -1
    }

    function parsePageMeta(doc, pageNode) {
        var contentNode = pageNode.children[0]
        doc.pageWidth = pageNode.offsetWidth
        doc.pageHeight = pageNode.offsetHeight
        doc.pageMargin = {
            top: contentNode.offsetTop,
            left: contentNode.offsetLeft
        }
        doc.pageMargin.right = doc.pageMargin.left
        doc.pageMargin.bottom = doc.pageMargin.top
        if (doc.pageWidth > doc.pageHeight)
            doc.orientation = 'landscape'
        else
            doc.orientation = 'portrait'
    }

    crossdoc.create = function(options) {
        this.pages = null

        this.parse = function(docId) {
            var root = document.getElementById(docId)
            this.pages = []
            this.images = {}

            for (var p=0; p<root.children.length; p++) {
                if (p === 0) {
                    parsePageMeta(this, root.children[p])
                }
                var page = parsePage(this, root.children[p])
                delete page.padding
                this.pages.push(page)
            }
        }

        this.toJSON = function(pretty) {
            var data = {
                images: this.images, pages: this.pages,
                page_width: this.pageWidth, page_height: this.pageHeight,
                page_margin: this.pageMargin, page_orientation: this.orientation
            }
            if (pretty)
                return JSON.stringify(data, undefined, 4)
            else
                return JSON.stringify(data)
        }

        return this
    }

    crossdoc.addOverlay = function(selector) {
        function appendObjView(parentView, obj) {
            if (!obj.box)
                return;
            var view = $('<div class="obj"></div>')
            var top = obj.box.y-1
            var height = obj.box.height+1
            if (obj.border && obj.border.top) {
                top += obj.border.top.width
                height -= (obj.border.top.width-1)
            }
            if (obj.border && obj.border.bottom)
                height -= obj.border.bottom.width
            view.css('top', top)
            view.css('height', height)
            var left = obj.box.x-1
            var width = obj.box.width + 1
            if (obj.border && obj.border.left) {
                left += obj.border.left.width
                width -= (obj.border.left.width-1)
            }
            if (obj.border && obj.border.right)
                width -= obj.border.right.width
            view.css('left', left)
            view.css('width', width)
            parentView.append(view)
            if (obj.children) {
                for (var i=0; i<obj.children.length; i++) {
                    appendObjView(view, obj.children[i])
                }
            }
        }
        var shadow = $(selector)
        var shadowElement = shadow[0]
        if (this.pages.length > shadowElement.children.length) {
            throw "The element to attach the overlay to only has " + shadowElement.children.length + ' children, but there are ' + this.pages.length + ' pages'
        }
        for (var p=0; p<this.pages.length; p++) {
            var page = this.pages[p]
            var overlay = $('<div class="crossdoc-overlay"></div>')
            var pageShadow = $(shadowElement.children[p]).find('.page-content')
            overlay.css('top', pageShadow.offset().top)
            overlay.css('left', pageShadow.offset().left)
            overlay.css('width', pageShadow.css('width'))
            overlay.css('height', pageShadow.css('height'))
            $('body').append(overlay)
            for (var i=0; i<page.children.length; i++) {
                appendObjView(overlay, page.children[i])
            }
        }
    }


    window.crossdoc = crossdoc
})()
