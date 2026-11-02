import Foundation
import Domain
@testable import BeansFeature

@MainActor
final class SpyRouter: BeanListRouting, BeanFormRouting {
    private(set) var shownDetailIDs: [Bean.ID] = []
    private(set) var addBeanShownCount = 0
    private(set) var finished: [Bean?] = []
    private(set) var deletedIDs: [Bean.ID] = []
    private(set) var notFoundCount = 0

    func showBeanDetail(id: Bean.ID) { shownDetailIDs.append(id) }
    func showAddBean() { addBeanShownCount += 1 }
    func beanForm(didFinish result: FormResult<Bean>) {
        switch result {
        case .added(let item), .updated(let item): finished.append(item)
        case .cancelled: finished.append(nil)
        case .deleted(let id): deletedIDs.append(id)
        case .notFound: notFoundCount += 1
        }
    }
}
