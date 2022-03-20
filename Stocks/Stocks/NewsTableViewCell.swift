//
//  NewsTableViewCell.swift
//  Stocks
//
//  Created by Арина Соколова on 13.02.2022.
//

import UIKit

class NewsTableViewCellViewModel {
    let headline: String
    let summary: String
    let image: URL?
    var imageData: Data? = nil
    let datetime: Int
    let url: URL?
    
    init(
        headline: String,
        summary: String,
        image: URL?,
        datetime: Int,
        url: URL?
    ) {
        self.headline = headline
        self.summary = summary
        self.image = image
        self.datetime = datetime
        self.url = url
    }
}

class NewsTableViewCell: UITableViewCell {
    static let identifier = "NewsTableViewCell"
    
    private let newsTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = UIColor(red: 3/255, green: 0, blue: 126/255, alpha: 1)
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 17, weight: .light)
        return label
    }()
    
    private let datetimeLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 19, weight: .medium)
        return label
    }()
    
    private let newsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 6
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(newsTitleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(datetimeLabel)
        contentView.addSubview(newsImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        newsTitleLabel.frame = CGRect(
            x: 10, y: 0,
            width: contentView.frame.size.width - 170,
            height: 70
        )
        
        subtitleLabel.frame = CGRect(
            x: 10, y: 70,
            width: contentView.frame.size.width - 170,
            height: 80
        )
        
        datetimeLabel.frame = CGRect(
            x: 10, y: 150,
            width: contentView.frame.size.width - 170,
            height: 30
        )
        
        newsImageView.frame = CGRect(
            x: contentView.frame.size.width-155,
            y: 5,
            width: 140,
            height: contentView.frame.size.height - 10
        )
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        newsTitleLabel.text = nil
        subtitleLabel.text = nil
        datetimeLabel.text = nil
        newsImageView.image = nil
    }
    
    func configure(with viewModel: NewsTableViewCellViewModel) {
        let epocTime = TimeInterval(viewModel.datetime) / 1000
        let myDate = Date(timeIntervalSince1970: epocTime)
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd.MM.yyyy"
        
        newsTitleLabel.text = viewModel.headline
        subtitleLabel.text = viewModel.summary
        datetimeLabel.text = dateFormatterPrint.string(from: myDate)
        
        if let data = viewModel.imageData {
            newsImageView.image = UIImage(data: data)
        }
        else if let url = viewModel.image {
            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else {
                    return
                }
                viewModel.imageData = data
                DispatchQueue.main.async {
                    self.newsImageView.image = UIImage(data: data)
                }
            }.resume()
        }
    }
}

