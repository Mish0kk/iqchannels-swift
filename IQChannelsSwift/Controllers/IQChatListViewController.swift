import UIKit
import Combine
import SwiftUI

class IQChatListViewController: IQViewController {
    
    // MARK: - PROPERTIES
    private let viewModel: IQChatListViewModel
    
    private let output: IQChannelsManagerListOutput
    
    private lazy var backButton: UIButton = {
        let btn: UIButton = .init(frame: .init(x: 0, y: 0, width: 24, height: 24))
        btn.setImage(UIImage(name: "chevron_left"), for: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.contentVerticalAlignment = .fill
        btn.contentHorizontalAlignment = .fill
        btn.addTarget(self, action: #selector(onTapBack), for: .touchUpInside)
        return btn
    }()
    
    // MARK: - INIT
    init(viewModel: IQChatListViewModel,
         output: IQChannelsManagerListOutput) {
        self.viewModel = viewModel
        self.output = output
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LIFECYCLE
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        output.listControllerDidAppear()
    }
    
    override func setupSwiftUI() {
        let hostView: ChatListView = .init(viewModel: viewModel, output: output)
        let controller: UIHostingController = .init(rootView: hostView)
        setupConstructedSwiftUI(interactor: controller)
        IQLog.debug(message: "2")
    }
    
    override func setupNavBar() {
        navigationItem.leftBarButtonItem = .init(customView: backButton)
        
        let backgroundColor = IQStyle.getUIColor(theme: IQStyle.model?.appBar?.background) ?? UIColor(hex: "ffffff")
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        
        IQLog.debug(message: "3")
    }
    
    override func bindViewModel() {
        viewModel.chatToPresentListener
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] controller in
                IQLog.debug(message: "4")
                guard let navigationController = self?.navigationController else { return }

                if navigationController.topViewController is IQChatDetailViewController {
                    var stack = navigationController.viewControllers
                    stack.removeLast()
                    stack.append(controller)
                    navigationController.setViewControllers(stack, animated: true)
                } else {
                    navigationController.pushViewController(controller, animated: true)
                }
                
                IQLog.debug(message: "5")
            }
            .store(in: &subscriptions)
        
        viewModel.dismissListener
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                dismiss(animated: true)
            }.store(in: &subscriptions)
        
        viewModel.popListener
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                navigationController?.popViewController(animated: true)
            }.store(in: &subscriptions)
    }
    
    // MARK: - ACTIONS
    @objc
    private func onTapBack() {
        output.listControllerDismissChat()
//        dismiss(animated: true)
    }
}
