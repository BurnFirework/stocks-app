//
//  ViewController.swift
//  Stocks
//
//  Created by Арина Соколова on 08.02.2022.
//

import UIKit
import SafariServices

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var companyLogo: UIImageView!
    @IBOutlet weak var newsTableView: UITableView!
    
    private let baseUrl = "https://cloud.iexapis.com/stable/stock"
    private let token = "pk_ec070263f99943f9aea0890211bd5327"
    
    private let connectionAlert: UIAlertController = {
        let alert = UIAlertController(
            title: "Ошибка интернет-соединения",
            message: "Проверьте подключение к интернету.",
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(
            UIAlertAction(
                title: "Ок",
                style: UIAlertAction.Style.default,
                handler: nil
            )
        )
        return alert
    }()
    
    private let newsAlert: UIAlertController = {
        let alert = UIAlertController(
            title: "Ошибка получения новостей.",
            message: "Попробуйте снова позже.",
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(
            UIAlertAction(
                title: "Ок",
                style: UIAlertAction.Style.default,
                handler: nil
            )
        )
        return alert
    }()
    
    private let companiesAlert: UIAlertController = {
        let alert = UIAlertController(
            title: "Ошибка IEXCloudAPI",
            message: "Получен пустой список компаний. Попробуйте зайти в приложение позже, чтобы увидеть актуальный список компаний.",
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(
            UIAlertAction(
                title: "Ок",
                style: UIAlertAction.Style.default,
                handler: nil
            )
        )
        return alert
    }()
    
    private let imageAlert: UIAlertController = {
        let alert = UIAlertController(
            title: "Ошибка загрузки изображения",
            message: "Проверьте подключение к интернету.",
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(
            UIAlertAction(
                title: "Ок",
                style: UIAlertAction.Style.default,
                handler: nil
            )
        )
        return alert
    }()
    
    private var companies: [String: String] = [
        "Apple": "AAPL",
        "Microsoft": "MSFT",
        "Google": "GOOG",
        "Amazon": "AMZN",
        "Facebook": "FB"
    ]
    
    private var viewModels = [NewsTableViewCellViewModel]();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Best Stocks"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(updateCompanies(_:)))
        self.companyPickerView.dataSource = self
        self.companyPickerView.delegate = self
        self.newsTableView.register(NewsTableViewCell.self, forCellReuseIdentifier: NewsTableViewCell.identifier)
        self.newsTableView.delegate = self
        self.newsTableView.dataSource = self
        self.activityIndicator.hidesWhenStopped = true
        self.getCompaniesAndRequestQuote()
    }
    
    override func viewDidLayoutSubviews() {
        self.companyLogo.layer.borderColor = CGColor.init(red: 0, green: 0, blue: 0, alpha: 1)
        self.companyLogo.layer.borderWidth = 2
        self.companyLogo.layer.cornerRadius = self.companyLogo.bounds.height / 2
        self.companyLogo.layer.masksToBounds = true
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.companies.keys.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(self.companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.activityIndicator.startAnimating()
        
        let selectedSymbol = Array(self.companies.values)[row]
        self.requestQuote(for: selectedSymbol)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: NewsTableViewCell.identifier,
            for: indexPath
        ) as? NewsTableViewCell else {
            fatalError()
        }
        cell.configure(with: viewModels[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let viewModel = viewModels[indexPath.row]
        guard let url = viewModel.url else {
            return
        }
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 190
    }
    
    @objc func updateCompanies(_ sender: UIBarButtonItem) {
        getCompaniesAndRequestQuote()
    }
    
    private func requestQuote(for symbol: String) {
        let url = URL(string: "\(baseUrl)/\(symbol)/quote?&token=\(token)")!
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil,
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let data = data
            else {
                DispatchQueue.main.async {
                    self.present(self.connectionAlert, animated: true, completion: nil)
                }
                return
            }
            
            self.parseQuote(data: data)
        }
        
        let getImageLinkUrl = URL(string: "\(baseUrl)/\(symbol)/logo?&token=\(token)")!
        
        let getImageLinkTask = URLSession.shared.dataTask(with: getImageLinkUrl) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.present(self.connectionAlert, animated: true, completion: nil)
                }
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                guard
                    let json = jsonObject as? [String: Any],
                    let imageUrl = json["url"] as? String
                else {
                    print("! Invalid JSON format")
                    return
                }
                let url = URL(string: imageUrl)!
                self.loadImage(imageUrl: url)
            } catch {
                print("! JSON parsing error: " + error.localizedDescription)
            }
        }
        
        dataTask.resume()
        getImageLinkTask.resume()
        requestNews(for: symbol)
    }
    
    private func loadImage(imageUrl: URL) {
        let imageTask = URLSession.shared.dataTask(with: imageUrl) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.present(self.imageAlert, animated: true, completion: nil)
                }
                return
            }
            DispatchQueue.main.async {
                self.companyLogo.image = UIImage(data: data)
            }
        }
        imageTask.resume()
    }
    
    private func parseQuote(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double
            else {
                print("! Invalid JSON format")
                return
            }
            DispatchQueue.main.async {
                self.displayStockInfo(
                    companyName: companyName,
                    symbol: companySymbol,
                    price: price,
                    priceChange: priceChange
                )
            }
        } catch {
            print("! JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func displayStockInfo(companyName: String, symbol: String, price: Double, priceChange: Double) {
        self.activityIndicator.stopAnimating()
        var trimmedName = companyName
        if trimmedName.count > 25 {
            trimmedName = String(companyName.prefix(25)) + "...";
        }
        self.companyNameLabel.text = trimmedName
        self.companySymbolLabel.text = symbol
        self.priceLabel.text = "$\(price)"
        self.priceChangeLabel.text = "\(priceChange)"
        if priceChange > 0 {
            self.priceChangeLabel.textColor = .systemGreen
            self.priceChangeLabel.text = "+\(priceChange)"
        }
        else if priceChange == 0 {
            self.priceChangeLabel.textColor = .black
        }
        else {
            self.priceChangeLabel.textColor = .red
        }
    }
    
    private func getCompaniesAndRequestQuote() {
        let getCompaniesUrl = URL(string: "\(baseUrl)/market/list/gainers?listLimit=10&token=\(token)")!
        let dataTask = URLSession.shared.dataTask(with: getCompaniesUrl) { data, response, error in
            guard error == nil,
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let data = data
            else {
                DispatchQueue.main.async {
                    self.present(self.connectionAlert, animated: true, completion: nil)
                }
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                guard
                    let json = jsonObject as? [[String: Any]]
                else {
                    print(jsonObject)
                    print("! Invalid JSON format")
                    return
                }
                
                if (json.isEmpty) {
                    DispatchQueue.main.async {
                        self.present(self.companiesAlert, animated: true, completion: nil)
                    }
                    return
                }
                
                for dict in json {
                    if let companyName = dict["companyName"] as? String,
                       let companySymbol = dict["symbol"] as? String {
                        self.companies[companyName] = companySymbol
                    }
                }
                
                DispatchQueue.main.async {
                    self.companyPickerView.reloadComponent(0)
                    self.requestQuoteUpdate()
                }
            } catch {
                print("! JSON parsing error: " + error.localizedDescription)
            }
        }
        dataTask.resume()
    }
    
    private func requestQuoteUpdate() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
            self.companyNameLabel.text = "-"
            self.companySymbolLabel.text = "-"
            self.priceLabel.text = "-"
            self.priceChangeLabel.text = "-"
            self.priceChangeLabel.textColor = .black
        }
        
        let selectedRow = self.companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(self.companies.values)[selectedRow]
        self.requestQuote(for: selectedSymbol)
    }
    
    private func requestNews(for symbol: String) {
        let url = URL(string: "\(baseUrl)/\(symbol)/news/last/?&token=\(token)")!
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil,
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let data = data
            else {
                DispatchQueue.main.async {
                    self.present(self.newsAlert, animated: true, completion: nil)
                }
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                guard
                    let json = jsonObject as? [[String: Any]]
                else {
                    print(jsonObject)
                    print("! Invalid JSON format")
                    return
                }
                
                if (json.isEmpty) {
                    DispatchQueue.main.async {
                        self.present(self.newsAlert, animated: true, completion: nil)
                    }
                    return
                }
                self.viewModels = []
                for dict in json {
                    guard
                        let headline = dict["headline"] as? String,
                        let summary = dict["summary"] as? String,
                        let datetime = dict["datetime"] as? Int,
                        let imageUrl = dict["image"] as? String,
                        let titleUrl = dict["url"] as? String,
                        let image = URL(string: imageUrl),
                        let url = URL(string: titleUrl)
                    else {
                        print("! Invalid JSON format")
                        return
                    }
                    let viewModel = NewsTableViewCellViewModel(headline: headline, summary: summary, image: image, datetime: datetime, url: url)
                    self.viewModels.append(viewModel)
                    DispatchQueue.main.async {
                        self.newsTableView.reloadData()
                    }
                }
                
            } catch {
                print("! JSON parsing error: " + error.localizedDescription)
            }
        }
        dataTask.resume()
    }
}

