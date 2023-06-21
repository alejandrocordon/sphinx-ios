//
//  MediaMessageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol MediaMessageViewDelegate: class {
    func didTapMediaButton()
}

class MediaMessageView: UIView {
    
    weak var delegate: MediaMessageViewDelegate?
    
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var mediaContainer: UIView!
    
    @IBOutlet weak var mediaImageView: UIImageView!
    @IBOutlet weak var paidContentOverlay: UIView!
    @IBOutlet weak var fileInfoView: FileInfoView!
    @IBOutlet weak var loadingContainer: UIView!
    @IBOutlet weak var loadingImageView: UIImageView!
    @IBOutlet weak var gifOverlay: GifOverlayView!
    @IBOutlet weak var videoOverlay: UIView!
    @IBOutlet weak var mediaNotAvailableView: UIView!
    @IBOutlet weak var mediaNotAvailableIcon: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("MediaMessageView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        mediaContainer.layer.cornerRadius = 8.0
        mediaContainer.clipsToBounds = true
    }
    
    func configureWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia,
        mediaData: MessageTableCellState.MediaData?,
        bubble: BubbleMessageLayoutState.Bubble,
        and delegate: MediaMessageViewDelegate?
    ) {
        self.delegate = delegate
        
        configureMediaNotAvailableIconWith(messageMedia: messageMedia)
        
        if let mediaData = mediaData {
            fileInfoView.isHidden = !messageMedia.isPdf || mediaData.failed
            gifOverlay.isHidden = !messageMedia.isGif || mediaData.failed
            videoOverlay.isHidden = !messageMedia.isVideo || mediaData.failed
            
            mediaImageView.image = mediaData.image
            mediaImageView.contentMode = messageMedia.isPaymentTemplate ? .scaleAspectFit : .scaleAspectFill
            
            if let fileInfo = mediaData.fileInfo {
                fileInfoView.configure(fileInfo: fileInfo)
                fileInfoView.isHidden = false
            } else {
                fileInfoView.isHidden = true
            }
            
            loadingContainer.isHidden = true
            loadingImageView.stopRotating()
            
            mediaNotAvailableView.isHidden = !mediaData.failed
            mediaNotAvailableIcon.isHidden = !mediaData.failed
        } else {
            mediaImageView.image = nil
            
            fileInfoView.isHidden = true
            videoOverlay.isHidden = true
            gifOverlay.isHidden = true
            paidContentOverlay.isHidden = true
            
            if messageMedia.isPaid && bubble.direction.isIncoming() {
                paidContentOverlay.isHidden = false
                mediaImageView.image = UIImage(named: "paidImageBlurredPlaceholder")
            } else {
                loadingContainer.isHidden = false
                loadingImageView.rotate()
            }
        }
    }
    
    func configureMediaNotAvailableIconWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia
    ) {
        if messageMedia.isPdf {
            mediaNotAvailableIcon.text = "picture_as_pdf"
        } else if messageMedia.isVideo {
            mediaNotAvailableIcon.text = "videocam"
        } else {
            mediaNotAvailableIcon.text = "photo_library"
        }
    }
    
    @IBAction func mediaButtonTouched() {
        delegate?.didTapMediaButton()
    }
}
