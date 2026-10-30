import Foundation
import Domain
@testable import BeansFeature

@MainActor
final class SpyRouter: BeanListRouting, BeanFormRouting {
    private(set) var shownDetailIDs: [Bean.ID] = []
    private(set) var addBeanShownCount = 0
    private(set) var finished: [Bean?] = []
    private(set) var deletedIDs: [Bean.ID] = []
    private(set) var notFoundIDs: [Bean.ID] = []

    func showBeanDetail(id: Bean.ID) { shownDetailIDs.append(id) }
    func showAddBean() { addBeanShownCount += 1 }
    func beanFormDidFinish(saved bean: Bean?) { finished.append(bean) }
    func beanFormDidDelete(id: Bean.ID) { deletedIDs.append(id) }
    func beanFormNotFound(id: Bean.ID) { notFoundIDs.append(id) }
}
