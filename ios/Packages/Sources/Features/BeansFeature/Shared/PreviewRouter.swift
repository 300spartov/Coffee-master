#if DEBUG
import Domain

/// No-op router for SwiftUI previews. Retained by `shared` because view models hold routers weakly.
final class PreviewRouter: BeanListRouting, BeanFormRouting {
    static let shared = PreviewRouter()

    func showBeanDetail(id: Bean.ID) {}
    func showAddBean() {}
    func beanForm(didFinish result: FormResult<Bean>) {}
}
#endif
