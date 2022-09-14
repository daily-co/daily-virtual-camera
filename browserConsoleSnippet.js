async function initGUM(fakeCameraName, fakeMedia) {
  const devices = await navigator.mediaDevices.enumerateDevices();
  let fakeCamera = devices.filter((dev) => fakeCameraName === dev.label);
  if (fakeCamera.length) {
    fakeCamera = fakeCamera[0];
  } else {
    const defaultCamera = devices.filter((dev) => 'videoinput' === dev.kind);
    fakeCamera = defaultCamera[0];
  }
  const video = document.createElement('video');
  video.setAttribute(
    'src',
    fakeMedia ||
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
  );
  video.setAttribute('crossorigin', 'anonymous');
  video.setAttribute('loop', true);
  video.volume = 0;
  let stream;

  navigator.mediaDevices.getUserMedia = new Proxy(
    navigator.mediaDevices.getUserMedia,
    {
      apply: (target, thisArg, argumentsList) => {
        if (argumentsList && argumentsList[0] && argumentsList[0].video) {
          if (
            JSON.stringify(argumentsList[0].video).includes(fakeCamera.deviceId)
          ) {
            video.play();
            stream = video.captureStream();
            return new Promise((res, rej) => {
              res(stream);
            });
          }
        }
        return Reflect.apply(target, thisArg, argumentsList);
      },
    }
  );
  console.log('____fake camera and media initialzed 🎥 ✔️');
}
await initGUM('viRTUALpyne camera (vipyne)');
