import SwiftUI

extension EnvironmentValues {
  @Entry var apiClient: APIClient = .fromBundle()
}
