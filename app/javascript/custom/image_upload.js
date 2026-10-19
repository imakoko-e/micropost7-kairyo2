// 巨大画像のアップロードを防止する
document.addEventListener("turbo:load", function() {
  const imageUploadInput = document.querySelector('#micropost_image');
  // 入力欄が無いページでは何もしない
  if (imageUploadInput) {
    imageUploadInput.addEventListener("change", function(event) {
      const file = event.target.files[0];

      if (file) {
        const size_in_megabytes = file.size / 1024 / 1024;
        if (size_in_megabytes > 5) {
          alert("最大ファイルサイズは5MBです。小さいファイルを選択してください。");
          event.target.value = ""; // ファイル選択をリセット
        }
      }
    });
  }

});
