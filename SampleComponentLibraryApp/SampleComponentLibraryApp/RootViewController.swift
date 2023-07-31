// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

class RootViewController: UIViewController, Presenter {
    // MARK: - Properties
    private let dataSource = ComponentDataSource()
    private let componentDelegate: ComponentDelegate

    private lazy var tableView: UITableView = .build { tableView in
        tableView.register(ComponentCell.self, forCellReuseIdentifier: ComponentCell.cellIdentifier)
        tableView.separatorStyle = .none
    }

    // MARK: - Init
    init() {
        componentDelegate = ComponentDelegate(componentData: dataSource.componentData)
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
        tableView.backgroundColor = .clear

        componentDelegate.presenter = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    private func setupTableView() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.dataSource = dataSource
        tableView.delegate = componentDelegate
        tableView.reloadData()
    }
}
