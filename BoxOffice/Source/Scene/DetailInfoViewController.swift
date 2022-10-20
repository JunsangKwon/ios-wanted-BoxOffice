//
//  DetailInfoViewController.swift
//  BoxOffice
//
//  Created by 권준상 on 2022/10/20.
//

import UIKit

class DetailInfoViewController: UIViewController {
    
    let detailInfoView = DetailInfoView()
    var simpleMovieInfo: SimpleMovieInfoEntity?
    var detailMovieInfo: DetailMovieInfoEntity?
    var standardInfoList: [StandardMovieInfoEntity] = []
    var sectionList: [SecondSection] = [.main, .standard]
    
    override func loadView() {
        view = detailInfoView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setCollectionView()
        getMovieInfo()
    }
    
    private func setCollectionView() {
        detailInfoView.collectionView.dataSource = self
        detailInfoView.collectionView.register(MainInfoCollectionViewCell.self, forCellWithReuseIdentifier: MainInfoCollectionViewCell.id)
        detailInfoView.collectionView.register(StandardInfoCollectionViewCell.self, forCellWithReuseIdentifier: StandardInfoCollectionViewCell.id)
        detailInfoView.collectionView.register(SubjectReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SubjectReusableView.id)
        detailInfoView.collectionView.collectionViewLayout = createBasicListLayout()
    }
    
    
    private func getMovieInfo() {
        Task {
            do {
                var data = try await NetworkManager.shared.getDetailMovieInfo(movieCd: simpleMovieInfo!.movieId)
                data.simpleInfo = simpleMovieInfo
                self.detailMovieInfo = data
                standardInfoList.removeAll()
                standardInfoList.append(StandardMovieInfoEntity(title: "감독", value: data.directors))
                standardInfoList.append(StandardMovieInfoEntity(title: "상영 시간", value: data.showTime + "분"))
                standardInfoList.append(StandardMovieInfoEntity(title: "연령 등급", value: data.watchGrade))
                standardInfoList.append(StandardMovieInfoEntity(title: "개봉일", value: data.openYear))
                standardInfoList.append(StandardMovieInfoEntity(title: "총 관객", value: data.simpleInfo!.audience + "명"))
                standardInfoList.append(StandardMovieInfoEntity(title: "제작 연도", value: data.productYear + "년"))
            } catch {
                print(error.localizedDescription)
            }
            await MainActor.run {
                detailInfoView.collectionView.reloadData()
            }
        }
    }
    
    private func createBasicListLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let sectionName = self.sectionList[sectionIndex]
            switch sectionName {
            case .main:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(250))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                               subitem: item, count: 1)
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .none
                
                return section
            case .standard:
                let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(60),
                                                      heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(2),
                                                       heightDimension: .estimated(100))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                               subitem: item, count: self.standardInfoList.count == 0 ? 6 : self.standardInfoList.count)
                group.interItemSpacing = .fixed(CGFloat(10))
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = .init(top: 0, leading: 8, bottom: 0, trailing: 8)
                section.boundarySupplementaryItems = [self.supplementaryHeaderItem()]
                
                return section
            }
        }
    }
    
    private func supplementaryHeaderItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        return .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40)), elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
    }
    
    
}

extension DetailInfoViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sectionList[section] {
        case .main:
            return detailMovieInfo == nil ? 0 : 1
        case .standard:
            return standardInfoList.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch sectionList[indexPath.section] {
        case .main:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MainInfoCollectionViewCell.id, for: indexPath) as? MainInfoCollectionViewCell else { return UICollectionViewCell() }
            guard let movie = self.detailMovieInfo else { return UICollectionViewCell() }
            
            Task {
                if let rank = movie.simpleInfo?.rank {
                    cell.rankingLabel.text = "\(rank)"
                }
                do {
                    cell.posterImageView.image = try await NetworkManager.shared.getPosterImage(englishName: movie.simpleInfo?.englishName ?? "")
                } catch {
                    print(error.localizedDescription)
                }
                if movie.simpleInfo?.inset.first == "-" {
                    cell.rankingChangeButton.tintColor = .systemBlue
                    cell.rankingChangeButton.setImage(UIImage(systemName: "arrow.down"), for: .normal)
                    cell.rankingChangeButton.setTitle(String(movie.simpleInfo?.inset.last! ?? Character("")), for: .normal)
                } else if movie.simpleInfo?.inset == "0" {
                    cell.rankingChangeButton.tintColor = .white
                    cell.rankingChangeButton.setImage(UIImage(systemName: "minus"), for: .normal)
                    cell.rankingChangeButton.setTitle(movie.simpleInfo?.inset, for: .normal)
                } else {
                    cell.rankingChangeButton.tintColor = .systemRed
                    cell.rankingChangeButton.setImage(UIImage(systemName: "arrow.up"), for: .normal)
                    cell.rankingChangeButton.setTitle(movie.simpleInfo?.inset, for: .normal)
                }
                if movie.simpleInfo?.oldAndNew == .new {
                    cell.newButton.isHidden = false
                } else {
                    cell.newButton.isHidden = true
                }
                cell.movieNameLabel.text = movie.simpleInfo?.name
                cell.openYearLabel.text = String(movie.openYear.prefix(4)) + " "
                var genreString = ""
                for i in 0..<movie.genreName.count {
                    if i == movie.genreName.count - 1 {
                        genreString += movie.genreName[i]
                    } else {
                        genreString += "\(movie.genreName[i]), "
                    }
                }
                cell.genreNameLabel.text = genreString
            }
            return cell
        case .standard:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StandardInfoCollectionViewCell.id, for: indexPath) as? StandardInfoCollectionViewCell else { return UICollectionViewCell() }
            cell.setData(data: standardInfoList[indexPath.item])
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SubjectReusableView.id, for: indexPath) as? SubjectReusableView else { return UICollectionReusableView() }
            header.setData(title: "기본 정보")
            return header
        default:
            return UICollectionReusableView()
        }
    }
    
    
}

enum SecondSection {
    case main
    case standard
}