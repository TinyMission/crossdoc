(function() {
    var crossdoc = {}

    // simple hash function to make unique string ids
    function hashCode(s) {
        return (s.split("").reduce(function(a,b){a=((a<<5)-a)+b.charCodeAt(0);return a&a},0) >>> 0).toString(16);
    }

    // processes a url to make sure it's absolute
    function processUrl(url) {
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
            if (s.length == 1)
                return '0' + s
            return s
        }
        function decToHex(vals) {
            return vals.map(function(val) {return twoChars(parseInt(val).toString(16))})
        }
        s = s.trim()
        if (s.indexOf('rgba(') == 0) {
            var comps = s.replace('rgba(', '').replace(')', '').split(', ')
            return '#' + decToHex(comps.slice(0,3)).join('') + twoChars((parseFloat(comps[3])*255).toString(16))
        }
        else if (s.indexOf('rgb(')==0) {
            var comps = s.replace('rgb(', '').replace(')', '').split(', ')
            return '#' + decToHex(comps).join('') + 'ff'
        }
        else {
            return s
        }
    }

    // returns true if a color string has a non-zero alpha
    function isVisibleColor(color) {
        if (color.length == 7)
            return true
        else if (color.length == 9) {
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
            if (border.width == 0)
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
        if (style.borderWidth.length > 0 && parseFloat(style.borderWidth.replace('px','')) > 0) {
            obj.border = parseBorder(style)
        }

        var background = parseBackground(style)
        if (isVisibleColor(background.color) || background.image) {
            obj.background = background
        }

        obj.padding = {
            top: parsePxString(style.paddingTop),
            right: parsePxString(style.paddingRight),
            bottom: parsePxString(style.paddingBottom),
            left: parsePxString(style.paddingLeft)
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
            align: style.textAlign=='start' ? 'left' : style.textAlign,
            transform: style.textTransform
        }
        if (style.lineHeight==='normal')
            obj.font.lineHeight = 1.2 * obj.font.size
        else
            obj.font.lineHeight = parsePxString(style.lineHeight)
    }

    // Recursively parses a node and its children
    function parseNode(doc, node) {
        var obj = {
            tag: node.tagName
        }
        if (isTagBlacklisted(obj.tag))
            return null

        var style = window.getComputedStyle(node)

        parseStyle(node, obj, style)

        // we only need box size for non-inline elements
        if (style.display != 'inline') {
            obj.box = {
                x: node.offsetLeft,
                y: node.offsetTop,
                width: node.offsetWidth,
                height: node.offsetHeight
            }
            // hack for wrong reporting of table-cell vertical offsets
            if (style.display === 'table-cell')
                obj.box.y = 0
        }

        // run the tag-specific parser, if one exists
        if (tagParsers.hasOwnProperty(obj.tag)) {
            tagParsers[obj.tag](doc, node, obj, style)
        }

        // parse the children
        var childNodes = node.childNodes
        var children = []
        var hasText = false
        for (var i = 0; i < childNodes.length; i++) {
            var childNode = childNodes[i]
            switch (childNode.nodeType) {
            case Node.ELEMENT_NODE:
                var childObj = parseNode(doc, childNode)
                if (childObj)
                    children.push(childObj)
                break
            case Node.TEXT_NODE:
                var text = childNode.data.trim()
                if (text.length > 0) {
                    children.push({tag: 'TEXT', text: text})
                    hasText = true
                }
                break
            default:
                console.log("Don't know what to do with node type " + childNode.nodeType)
                console.log(childNode)
            }
        }

        // parse text styles
        if (hasText)
            parseTextStyle(node, obj, style)

        // flatten single text nodes
        if (children.length == 1 && children[0].tag=='TEXT') {
            obj.text = children[0].text
        }
        else if (children.length > 0) {
            obj.children = children
        }

        return obj
    }

    function parsePage(doc, node) {
        var page = {
            width: node.offsetWidth,
            height: node.offsetHeight,
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
        var childNodes = node.childNodes
        for (var i = 0; i < childNodes.length; i++) {
            var childNode = childNodes[i]
            switch (childNode.nodeType) {
            case Node.ELEMENT_NODE:
                var childObj = parseNode(doc, childNode)
                if (childObj)
                    page.children.push(childObj)
                break
            case Node.TEXT_NODE:
                var text = childNode.data.trim()
                if (text.length > 0) {
                    page.children.push({tag: 'TEXT', text: text})
                }
                break
            default:
                console.log("Don't know what to do with node type " + childNode.nodeType)
                console.log(childNode)
            }
        }
        return page
    }

    var tagParsers = {}

    tagParsers.IMG = function(doc, node, obj, style) {
        obj.src = processUrl(node.getAttribute('src'))
        obj.hash = hashCode(obj.src)
        doc.images[obj.hash] = {src: obj.src, hash: obj.hash}
    }

    tagParsers.INPUT = function(doc, node, obj, style) {
        obj.inputType = node.getAttribute('type')
        obj.inputValue = node.getAttribute('value')
    }

    tagParsers.UL = function(doc, node, obj, style) {
        obj.listStyle = style.listStyle
    }
    tagParsers.OL = tagParsers.UL

    // don't parse these tags, they aren't a part of the visible DOM
    var tagBlacklist = ['OPTION', 'SCRIPT']

    function isTagBlacklisted(tag) {
        return tagBlacklist.indexOf(tag) > -1
    }


    crossdoc.create = function(options) {
        this.pages = null

        this.parse = function(docId) {
            var root = document.getElementById(docId)
            this.pages = []
            this.images = {}

            for (var p=0; p<root.children.length; p++) {
                var page = parsePage(this, root.children[p])
                this.pages.push(page)
            }
        }

        this.toJSON = function(pretty) {
            var data = {images: this.images, pages: this.pages}
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
            var pageShadow = $(shadowElement.children[p])
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
