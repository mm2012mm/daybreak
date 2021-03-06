/*
SBHistoryView.swift

Copyright (c) 2014, Alice Atlas
Copyright (c) 2010, Atsushi Jike
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import BLKGUI

class SBHistoryView: SBView, NSTextFieldDelegate, NSTableViewDelegate, NSTableViewDataSource, NSSearchFieldDelegate {
    private let kSBMinFrameSizeWidth: CGFloat = 480
    private let kSBMinFrameSizeHeight: CGFloat = 320
    
	private lazy var iconImageView: NSImageView = {
        let iconImageView = NSImageView(frame: self.iconRect)
        if let image = NSImage(named: "History") {
            image.size = iconImageView.frame.size
            iconImageView.image = image
        }
        return iconImageView
    }()
	private lazy var messageLabel: NSTextField = {
        let messageLabel = NSTextField(frame: self.messageLabelRect)
        messageLabel.autoresizingMask = [.ViewMinXMargin, .ViewMinYMargin]
        messageLabel.editable = false
        messageLabel.bordered = false
        messageLabel.drawsBackground = false
        messageLabel.textColor = .whiteColor()
        messageLabel.font = .boldSystemFontOfSize(16)
        messageLabel.alignment = .Left
        messageLabel.cell!.wraps = true
        return messageLabel
    }()
	private lazy var searchField: BLKGUI.SearchField = {
        let searchField = BLKGUI.SearchField(frame: self.searchFieldRect)
        (searchField as NSTextField).delegate = self
        searchField.target = self
        searchField.action = #selector(search(_:))
        searchField.cell!.sendsWholeSearchString = true
        searchField.cell!.sendsSearchStringImmediately = true
        return searchField
    }()
	private lazy var scrollView: BLKGUI.ScrollView = {
        let scrollView = BLKGUI.ScrollView(frame: self.tableViewRect)
        scrollView.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        scrollView.autohidesScrollers = true
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .blackColor()
        scrollView.drawsBackground = false
        scrollView.documentView = self.tableView
        return scrollView
    }()
	private lazy var tableView: NSTableView = {
        var tableRect = NSZeroRect
        tableRect.size = self.tableViewRect.size
        let tableView = NSTableView(frame: tableRect)
        let iconColumn = NSTableColumn(identifier: kSBImage)
        let titleColumn = NSTableColumn(identifier: kSBTitle)
        let URLColumn = NSTableColumn(identifier: kSBURL)
        let dateColumn = NSTableColumn(identifier: kSBDate)
        let iconCell = SBIconDataCell()
        let textCell = NSCell()
        iconCell.drawsBackground = false
        iconColumn.width = 22.0
        iconColumn.dataCell = iconCell
        iconColumn.editable = false
        titleColumn.dataCell = textCell
        titleColumn.width = (tableRect.size.width - 22.0) * 0.3
        titleColumn.editable = false
        URLColumn.dataCell = textCell
        URLColumn.width = (tableRect.size.width - 22.0) * 0.4
        URLColumn.editable = false
        dateColumn.dataCell = textCell
        dateColumn.width = (tableRect.size.width - 22.0) * 0.3
        dateColumn.editable = false
        tableView.backgroundColor = .clearColor()
        tableView.rowHeight = 20
        tableView.addTableColumn(iconColumn)
        tableView.addTableColumn(titleColumn)
        tableView.addTableColumn(URLColumn)
        tableView.addTableColumn(dateColumn)
        tableView.allowsMultipleSelection = true
        tableView.allowsColumnSelection = false
        tableView.allowsEmptySelection = true
        tableView.doubleAction = "tableViewDidDoubleAction:"
        tableView.columnAutoresizingStyle = .LastColumnOnlyAutoresizingStyle
        tableView.headerView = nil
        tableView.cornerView = nil
        tableView.autoresizingMask = .ViewWidthSizable
        tableView.setDataSource(self)
        tableView.setDelegate(self)
        tableView.focusRingType = .None
        tableView.doubleAction = #selector(open)
        return tableView
    }()
	private lazy var removeButton: BLKGUI.Button = {
        let removeButton = BLKGUI.Button(frame: self.removeButtonRect)
        removeButton.title = NSLocalizedString("Remove", comment: "")
        removeButton.target = self
        removeButton.action = #selector(remove)
        removeButton.enabled = false
        return removeButton
    }()
	private lazy var removeAllButton: BLKGUI.Button = {
        let removeAllButton = BLKGUI.Button(frame: self.removeAllButtonRect)
        removeAllButton.title = NSLocalizedString("Remove All", comment: "")
        removeAllButton.target = self
        removeAllButton.action = #selector(removeAll)
        removeAllButton.enabled = false
        return removeAllButton
    }()
	private lazy var backButton: BLKGUI.Button = {
        let backButton = BLKGUI.Button(frame: self.backButtonRect)
        backButton.title = NSLocalizedString("Back", comment: "")
        backButton.target = self
        backButton.action = #selector(cancel)
        backButton.keyEquivalent = "\u{1B}"
        return backButton
    }()
    
    var message: String {
        get { return messageLabel.stringValue }
        set(message) { messageLabel.stringValue = message }
    }
	var items: [WebHistoryItem]
    
    override init(frame: NSRect) {
        var r = frame
        r.size.width.constrain(min: kSBMinFrameSizeWidth)
        r.size.height.constrain(min: kSBMinFrameSizeWidth)
        items = SBHistory.sharedHistory.items
        super.init(frame: r)
        addSubviews(iconImageView, messageLabel, searchField, scrollView, removeButton, removeAllButton, backButton)
        makeResponderChain()
        autoresizingMask = [.ViewMinXMargin, .ViewMaxXMargin, .ViewMinYMargin, .ViewMaxYMargin]
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    // MARK: Rects
    
    let margin = NSMakePoint(36.0, 32.0)
    let labelWidth: CGFloat = 85.0
    let buttonHeight: CGFloat = 24.0
    let buttonMargin: CGFloat = 15.0
    let searchFieldWidth: CGFloat = 250.0
    
    var iconRect: NSRect {
        var r = NSZeroRect
        r.size.width = 32.0
        r.origin.x = labelWidth - r.size.width
        r.size.height = 32.0
        r.origin.y = bounds.size.height - margin.y - r.size.height
        return r
    }
    
    var messageLabelRect: NSRect {
        var r = NSZeroRect
        r.origin.x = iconRect.maxX + 10.0
        r.size.width = bounds.size.width - r.origin.x - searchFieldWidth - margin.x
        r.size.height = 20.0
        r.origin.y = bounds.size.height - margin.y - r.size.height - (iconRect.size.height - r.size.height) / 2
        return r
    }
    
    var searchFieldRect: NSRect {
        var r = NSZeroRect
        r.size.width = searchFieldWidth
        r.size.height = 20.0
        r.origin.x = bounds.size.width - r.size.width - margin.x
        r.origin.y = bounds.size.height - margin.y - r.size.height - (iconRect.size.height - r.size.height) / 2
        return r
    }
    
    var tableViewRect: NSRect {
        var r = NSZeroRect
        r.origin.x = margin.x
        r.size.width = bounds.size.width - r.origin.x - margin.x
        r.size.height = bounds.size.height - iconRect.size.height - 10.0 - margin.y * 3 - buttonHeight
        r.origin.y = margin.y * 2 + buttonHeight
        return r
    }
    
    var removeButtonRect: NSRect {
        var r = NSZeroRect
        r.size.width = 105.0
        r.size.height = buttonHeight
        r.origin.y = margin.y
        r.origin.x = margin.x
        return r
    }
    
    var removeAllButtonRect: NSRect {
        var r = NSZeroRect
        r.size.width = 140.0
        r.size.height = removeButtonRect.size.height
        r.origin.y = margin.y
        r.origin.x = removeButtonRect.maxX + 10.0
        return r
    }
    
    var backButtonRect: NSRect {
        var r = NSZeroRect
        r.size.width = 105.0
        r.size.height = buttonHeight
        r.origin.y = margin.y
        r.origin.x = bounds.size.width - r.size.width - margin.x
        return r
    }
    
    func showAllItems() {
        items = SBHistory.sharedHistory.items
        tableView.reloadData()
    }
    
    func updateItems() {
        let allItems = SBHistory.sharedHistory.items
        let searchFieldText = searchField.stringValue
        if let searchWords = searchFieldText.ifNotEmpty?.componentsSeparatedByCharactersInSet(.whitespaceCharacterSet()).ifNotEmpty {
            items = []
            for item in allItems {
                var string = ""
                item.originalURLString !! { string += " \($0)" }
                item.URLString !! { string += " \($0)" }
                item.title !! { string += " \($0)" }
                if !string.isEmpty {
                    for (index, searchWord) in enumerate(searchWords) {
                        if searchWord.isEmpty || string.rangeOfString(searchWord, options: .CaseInsensitiveSearch) != nil {
                            if index == searchWords.count - 1 {
                                items.append(item)
                            }
                        } else {
                            break
                        }
                    }
                }
            }
        } else {
            items = allItems
        }
    }
    
    // MARK: DataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        removeAllButton.enabled = !items.isEmpty
        return items.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row rowIndex: Int) -> AnyObject? {
        let identifier = tableColumn!.identifier
        let item = items.get(rowIndex)
        switch identifier {
        case kSBTitle:
            return item?.title
        case kSBURL:
            return item?.URLString
        case kSBDate:
            return nil
        default:
            break
        }
        return nil
    }
    
    func tableView(tableView: NSTableView, willDisplayCell aCell: AnyObject, forTableColumn tableColumn: NSTableColumn?, row rowIndex: Int) {
        let identifier = tableColumn!.identifier
        let item = items.get(rowIndex)
        let cell = aCell as! NSCell
        var string: String?
        switch identifier {
            case kSBImage:
                if let image = item?.icon {
                    cell.image = image
                }
            case kSBTitle:
                string = item?.title
            case kSBURL:
                string = item?.URLString
            case kSBDate:
                let interval = item?.lastVisitedTimeInterval ?? 0
                if interval > 0 {
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "%Y/%m/%d %H:%M:%S"
                    dateFormatter.formatterBehavior = .Behavior10_4
                    dateFormatter.dateStyle = .LongStyle
                    dateFormatter.timeStyle = .ShortStyle
                    dateFormatter.locale = .currentLocale()
                    string = dateFormatter.stringFromDate(NSDate(timeIntervalSince1970: interval))
                }
            default:
                break
        }
        if let string = string?.ifNotEmpty {
            let attributes = [NSFontAttributeName: NSFont.systemFontOfSize(14.0),
                              NSForegroundColorAttributeName: NSColor.whiteColor()]
            let attributedString = NSAttributedString(string: string, attributes: attributes)
            cell.attributedStringValue = attributedString
        }
    }
    
    // MARK: Delegate
    
    override func controlTextDidChange(notification: NSNotification) {
        if notification.object === searchField {
            if searchField.stringValue.isEmpty {
                showAllItems()
            }
        }
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        removeButton.enabled = tableView.selectedRowIndexes.count > 0
    }
    
    // MARK: Construction
    
    func makeResponderChain() {
        removeButton.nextKeyView = removeAllButton
        backButton.nextKeyView = removeButton
        tableView.nextKeyView = backButton
        removeAllButton.nextKeyView = tableView
    }
    
    // MARK: Actions
    
    func search(sender: AnyObject) {
        if !searchField.stringValue.isEmpty {
            updateItems()
            tableView.reloadData()
        }
    }
    
    func remove() {
        let indexes = tableView.selectedRowIndexes
        if let removedItems = items.objectsAtIndexes(indexes).ifNotEmpty {
            SBHistory.sharedHistory.removeItems(removedItems)
            tableView.deselectAll(nil)
            updateItems()
            tableView.reloadData()
        }
    }
    
    func removeAll() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Are you sure you want to remove all items?", comment: "")
        alert.addButtonWithTitle(NSLocalizedString("Remove All", comment: ""))
        alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
        if alert.runModal() == NSAlertFirstButtonReturn {
            SBHistory.sharedHistory.removeAllItems()
            tableView.deselectAll(nil)
            updateItems()
            tableView.reloadData()
        }
    }
    
    func open() {
        var URLs: [NSURL] = []
        let indexes = tableView.selectedRowIndexes
        for var index = indexes.lastIndex; index != NSNotFound; index = indexes.indexLessThanIndex(index) {
            let item = items.get(index)
            let URLString = item?.URLString
            if let URL = URLString !! {NSURL(string: $0)} {
                URLs.append(URL)
            }
        }
        if target?.respondsToSelector(doneSelector) ?? false {
            NSApp.sendAction(doneSelector, to: target, from: URLs)
        }
    }
}