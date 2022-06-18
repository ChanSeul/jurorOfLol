# 롤재판소
## 프로젝트 소개
5대5 팀게임, 리그오브레전드를 플레이할 때마다 의견이 다른 팀원과 마찰이 생기는 경우가 많습니다.  
유튜브에 업로드한 리플레이 동영상을 공유하고 투표를 시작하여, 다른 유저들이 어떤 의견에 동의하는지 알 수 있습니다.  
[앱스토어 링크](https://apps.apple.com/kr/app/%EB%A1%A4-%EC%9E%AC%ED%8C%90%EC%86%8C/id1616538910)
- 홈 화면  
  
  게시글과 동영상을 보고 투표바를 클릭하여 투표를 할 수 있습니다.
  로그인 상태에서만 투표와 업로드를 할 수 있으며, 비로그인 상태에서 투표바와 우측 하단의 업로드 버튼을 누를시, 로그인창이 나타납니다. 또한 우측 상단 버튼을 클릭한 후, 게시글을 최신순 또는 총 투표수로
  정렬할 수 있습니다.  
  
  ![IMG_0386](https://user-images.githubusercontent.com/37011809/164245844-3dcb8726-d21b-4971-abd0-b3003a78fc29.PNG)
  ![KakaoTalk_Photo_2022-04-20-19-15-42](https://user-images.githubusercontent.com/37011809/164245817-6a71e8cd-0d63-4a9d-ac48-ce863a24ef58.png)  
  
- 업로드 화면  
  
  홈 화면의 우측하단의 업로드 버튼을 누르면, 업로드화면이 나타납니다. 모든 항목이 입력되어야 업로드되며, 본인의 주장은 상단바에, 상대방의 주장은 하단바에 나타납니다.  
    
  ![IMG_0381](https://user-images.githubusercontent.com/37011809/164245840-9e4d926b-045f-4693-b99d-99b51fd6495a.PNG)
## 아키텍쳐
![빈 페이지-1](https://user-images.githubusercontent.com/37011809/174434081-1bcc7d24-65c2-4018-954f-b7e7391481eb.png)

- MVVM

  ViewController는 인터페이스를 다루는 로직을 담당하고, ViewModel은 데이터를 다루는 로직을 담당하도록 하여, 각 요소들이 독립적으로 테스트될 수 있도록 만들었습니다.
- Clean Architecture

  소스코드의 의존성을 저수준에서 고수준으로 향하도록 만들어 (Application -> Platform -> Domain), 고수준의 정책이 저수준의 잦은 변경사항에 영향을 받지 않도록 하였습니다. 
- Coordinator Pattern

  Navigation Logic을 ViewController로부터 분리하여 Viewcontroller들 사이의 의존성을 줄였습니다.
## 실행환경
- iOS 13.0 이상
