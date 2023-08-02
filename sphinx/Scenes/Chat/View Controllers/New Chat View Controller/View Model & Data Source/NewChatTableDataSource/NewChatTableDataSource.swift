//
//  NewChatTableDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData
import WebKit

protocol NewChatTableDataSourceDelegate : class {
    ///New msgs indicator
    func configureNewMessagesIndicatorWith(newMsgCount: Int)
    
    ///Scrolling
    func didScrollToBottom()
    func didScrollToTop()
    func didScrollOutOfStartArea()
    func didScroll()
    
    ///Attachments
    func shouldGoToAttachmentViewFor(messageId: Int, isPdf: Bool)
    func shouldGoToVideoPlayerFor(messageId: Int, with data: Data)
    
    ///LinkPreviews
    func didTapOnContactWith(pubkey: String, and routeHint: String?)
    func didTapOnTribeWith(joinLink: String)
    
    ///Tribes
    func didDeleteTribe()
    
    ///First messages / Socket
    func didUpdateChat(_ chat: Chat)
    
    ///Message menu
    func didLongPressOn(cell: UITableViewCell, with messageId: Int, bubbleViewRect: CGRect, isThreadRow: Bool)
    
    ///Leaderboard
    func shouldShowLeaderboardFor(messageId: Int)
    
    ///Message reply
    func shouldReplyToMessage(message: TransactionMessage)
    
    ///File download
    func shouldOpenActivityVCFor(url: URL)
    
    ///Invoices
    func shouldPayInvoiceFor(messageId: Int)
    
    ///Messages search
    func isOnStandardMode() -> Bool
    func didFinishSearchingWith(matchesCount: Int, index: Int)
    func shouldToggleSearchLoadingWheel(active: Bool)
    
    ///Threads
    func shouldShowThreadFor(message: TransactionMessage)
}

class NewChatTableDataSource : NSObject {
    
    ///Delegate
    weak var delegate: NewChatTableDataSourceDelegate?
    
    ///View references
    var tableView : UITableView!
    var newMsgIndicator : NewMessagesIndicatorView!
    var headerImage: UIImage?
    var bottomView: UIView!
    var webView: WKWebView!
    
    ///Chat
    var chat: Chat?
    var contact: UserContact?
    var owner: UserContact? = nil
    
    ///Data Source related
    var messagesResultsController: NSFetchedResultsController<TransactionMessage>!
    var additionMessagesResultsController: NSFetchedResultsController<TransactionMessage>!
    
    var currentDataSnapshot: DataSourceSnapshot!
    var dataSource: DataSource!
    
    ///Helpers
    var preloaderHelper = MessagesPreloaderHelper.sharedInstance
    let linkPreviewsLoader = CustomSwiftLinkPreview.sharedInstance
    let messageBubbleHelper = NewMessageBubbleHelper()
    let audioPlayerHelper = AudioPlayerHelper()
    var podcastPlayerController = PodcastPlayerController.sharedInstance
    
    ///Messages Data
    var messagesArray: [TransactionMessage] = []
    var messageTableCellStateArray: [MessageTableCellState] = []
    var mediaCached: [Int: MessageTableCellState.MediaData] = [:]
    var botsWebViewData: [Int: MessageTableCellState.BotWebViewData] = [:]
    var uploadingProgress: [Int: MessageTableCellState.UploadProgressData] = [:]
    
    var searchingTerm: String? = nil
    var searchMatches: [(Int, MessageTableCellState)] = []
    var currentSearchMatchIndex: Int = 0
    var isLastSearchPage = false
    
    ///Scroll and pagination
    var messagesCount = 0
    var loadingMoreItems = false
    var scrolledAtBottom = false
    
    ///WebView Loading
    let webViewSemaphore = DispatchSemaphore(value: 1)
    var webViewLoadingCompletion: ((CGFloat?) -> ())? = nil
    
    init(
        chat: Chat?,
        contact: UserContact?,
        tableView: UITableView,
        newMsgIndicator : NewMessagesIndicatorView,
        headerImageView: UIImageView?,
        bottomView: UIView,
        webView: WKWebView,
        delegate: NewChatTableDataSourceDelegate?
    ) {
        super.init()
        
        self.chat = chat
        self.contact = contact
        self.owner = UserContact.getOwner()
        
        self.tableView = tableView
        self.newMsgIndicator = newMsgIndicator
        self.headerImage = headerImageView?.image
        self.bottomView = bottomView
        self.webView = webView
        
        self.delegate = delegate
        
        configureTableView()
        configureDataSource()
        processChatAliases()
    }
    
    func processChatAliases() {
        DispatchQueue.global(qos: .background).async {
            self.chat?.processAliases()
        }
    }
    
    func isFinalDS() -> Bool {
        return self.chat != nil
    }
    
    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200.0
        tableView.contentInset.top = Constants.kMargin
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        configureTableTransform()
        
        tableView.registerCell(NewMessageTableViewCell.self)
        tableView.registerCell(MessageNoBubbleTableViewCell.self)
        tableView.registerCell(NewOnlyTextMessageTableViewCell.self)
    }
    
    func configureTableTransform() {
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    func configureTableCellTransformOn(cell: ChatTableViewCellProtocol?) {
        cell?.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
}
