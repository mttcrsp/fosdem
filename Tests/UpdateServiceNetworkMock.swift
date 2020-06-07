@testable
import Fosdem

struct UpdateServiceNetworkMock: UpdateServiceNetwork {
  let result: Result<AppStoreSearchResponse, Error>

  func perform(_ request: AppStoreSearchRequest, completion: @escaping (Result<AppStoreSearchResponse, Error>) -> Void) -> NetworkServiceTask {
    completion(result)
    return NetworkServiceTaskMock()
  }
}
