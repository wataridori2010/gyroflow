fn main() {
    let qt_include_path = std::env::var("DEP_QT_INCLUDE_PATH").unwrap();
    let qt_library_path = std::env::var("DEP_QT_LIBRARY_PATH").unwrap();
    let qt_version      = std::env::var("DEP_QT_VERSION").unwrap();

    #[allow(unused_mut)]
    let mut config = cpp_build::Config::new();

    if cfg!(target_os = "macos") {
        config.flag("-F");
        config.flag(&qt_library_path);
        println!("cargo:rustc-link-lib=z");
        println!("cargo:rustc-link-lib=bz2");
        println!("cargo:rustc-link-lib=xml2");
        println!("cargo:rustc-link-lib=framework=VideoToolbox");
        println!("cargo:rustc-link-lib=framework=CoreAudio");
    }

    let mut public_include = |name| { config.include(format!("{}/{}", qt_include_path, name)); };
    public_include("QtCore");
    public_include("QtGui");
    public_include("QtQuick");
    public_include("QtQml");
    public_include("QtQuickControls2");

    let mut private_include = |name| { config.include(format!("{}/{}/{}",    qt_include_path, name, qt_version))
                                             .include(format!("{}/{}/{}/{}", qt_include_path, name, qt_version, name)); };
    private_include("QtCore");

    config
        .include(&qt_include_path)
        .flag_if_supported("-std=c++17")
        .flag_if_supported("/std:c++17")
        .flag_if_supported("/Zc:__cplusplus")
        .build("src/gyroflow.rs");

    let target_os = std::env::var("CARGO_CFG_TARGET_OS");
    match target_os.as_ref().map(|x| &**x) {
        Ok("android") => {
            println!("cargo:rustc-link-search={}/ext/ffmpeg-4.4-android-lite/lib/arm64-v8a", std::env::var("CARGO_MANIFEST_DIR").unwrap());
        },
        Ok("macos") => {
            
        },
        Ok("windows") => {
            let mut res = winres::WindowsResource::new();
            res.set_icon("resources/app_icon.ico");
            res.compile().unwrap();
        }
        tos => panic!("unknown target os {:?}!", tos)
    }

}
