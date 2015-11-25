Pod::Spec.new do |s|
  s.name          = "CKCollectionViewDataSourceChangesetBuilder"
  s.version       = "0.9.2"
  s.summary       = "DSL changeset builder for ComponentKit."
  s.description   = "Provides a builder pattern DSL for creating CKTransactionalComponentDataSourceChangeset instances"
  s.homepage      = "https://github.com/itsthejb/CKCollectionViewDataSourceChangesetBuilder"
  s.license       = { :type => 'MIT', :file => 'LICENSE' }
  s.author        = { "Jonathan Crooke" => "jon.crooke@gmail.com" }
  s.source        = { :git => "https://github.com/itsthejb/CKCollectionViewDataSourceChangesetBuilder.git", :tag => "v" + s.version.to_s }
  s.ios.deployment_target = '7.0'
  s.source_files  = s.name + '/**/*.{h,mm}'
  s.frameworks    = 'UIKit'
	s.dependency 'ComponentKit', '>= 0.13'
end
