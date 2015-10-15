//
//  ToDoListViewController.swift
//  SwiftMVVMBinding
//
//  Created by Darren Clark on 2015-10-15.
//  Copyright © 2015 Darren Clark. All rights reserved.
//

import UIKit
import SwiftMVVMBinding


class ToDoListViewController : UIViewController {
    
    let viewModel = ToDoListViewModel()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var addButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.b_configure(viewModel.toDoItems) { config in
            config.usingCellIdentifier("Cell") { item, cell in
                cell.textLabel?.text = item
            }
            config.onSelect(viewModel.markToDoCompleted)
        }
        
        addButton.b_onTap(viewModel.addToDo)
    }
    
    @IBAction func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
