module Creditsafe
  class Error < StandardError; end

  class ApiError < Error; end
  class HttpError < Error; end
end
