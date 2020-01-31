/*
 * Copyright 2020 Square Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#if canImport(UIKit)

import UIKit


public struct ViewControllerDescription {

    private let _type: UIViewController.Type
    private let _build: (ContainerHints) -> UIViewController
    private let _update: (UIViewController, ContainerHints) -> Void

    public init<VC: UIViewController>(build: @escaping (ContainerHints) -> VC, update: @escaping (VC, ContainerHints) -> Void) {
        _type = VC.self
        _build = build
        _update = { untypedViewController, hints in
            guard let viewController = untypedViewController as? VC else {
                fatalError("Unable to update \(untypedViewController), expecting a \(VC.self)")
            }
            update(viewController, hints)
        }
    }

    func buildViewController(hints: ContainerHints) -> UIViewController {
        let viewController = _build(hints)
        _update(viewController, hints)
        return viewController
    }

    func canUpdate(viewController: UIViewController) -> Bool {
        return type(of: viewController) == _type
    }

    func update(viewController: UIViewController, hints: ContainerHints) {
        _update(viewController, hints)
    }

}

#endif