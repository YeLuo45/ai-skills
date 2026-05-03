#!/usr/bin/env python3
"""PyAutoGUI 桌面自动化快速验证脚本 — Windows 版

运行方式:
  保存到桌面 -> CMD 运行: cd %USERPROFILE%\Desktop && python desktop_automation_verify.py

依赖安装:
  pip install pyautogui opencv-python pillow
"""
import sys
import os

def main():
    print("=== PyAutoGUI 桌面自动化验证 ===\n")

    # 1. 依赖检查
    print("[1] 依赖检查")
    deps = {}
    for name, import_name in [("PyAutoGUI", "pyautogui"), ("OpenCV", "cv2"), ("Pillow", "PIL")]:
        try:
            mod = __import__(import_name)
            ver = getattr(mod, "__version__", "unknown")
            deps[name] = ver
            print(f"  {name}: OK ({ver})")
        except ImportError:
            deps[name] = None
            print(f"  {name}: MISSING")

    # 2. 屏幕信息
    print("\n[2] 屏幕信息")
    import pyautogui
    w, h = pyautogui.size()
    print(f"  屏幕尺寸: {w} x {h}")
    print(f"  FAILSAFE: {pyautogui.FAILSAFE}")
    print(f"  PAUSE: {pyautogui.PAUSE}")

    # 3. 鼠标位置
    print("\n[3] 鼠标位置")
    x, y = pyautogui.position()
    print(f"  当前位置: ({x}, {y})")
    print(f"  在屏幕范围内: {pyautogui.onScreen(x, y)}")

    # 4. 截图测试
    print("\n[4] 截图测试")
    desktop = os.path.join(os.path.expanduser("~"), "Desktop")
    out_path = os.path.join(desktop, "desktop_automation_test.png")
    screenshot = pyautogui.screenshot()
    screenshot.save(out_path)
    print(f"  截图已保存: {out_path}")
    print(f"  截图尺寸: {screenshot.size}")

    # 5. API 可用性检查
    print("\n[5] API 可用性检查")
    apis = ["moveTo", "click", "write", "press", "hotkey", "scroll",
            "locateOnScreen", "locateCenterOnScreen", "alert", "confirm", "prompt"]
    for api in apis:
        avail = hasattr(pyautogui, api)
        print(f"  pyautogui.{api}: {'OK' if avail else 'MISSING'}")

    # 6. OpenCV 图像识别增强
    print("\n[6] OpenCV 图像识别")
    try:
        import cv2
        print(f"  OpenCV 可用，版本: {cv2.__version__}")
        print("  locateOnScreen 将使用 OpenCV 加速（高精度）")
    except ImportError:
        print("  WARNING: OpenCV 未安装，图像识别使用 Pillow（精度较低）")
        print("  建议安装: pip install opencv-python")

    # 7. 总结
    print("\n=== 验证结果 ===")
    all_ok = all(v is not None for v in deps.values())
    if all_ok:
        print("所有依赖已就绪，PyAutoGUI 可用")
        print("\n将鼠标移到屏幕角落可触发 FAILSAFE 紧急停止")
    else:
        missing = [k for k, v in deps.items() if v is None]
        print(f"缺少依赖: {', '.join(missing)}")
        print("\n安装命令:")
        print("  pip install pyautogui opencv-python pillow")
        sys.exit(1)

if __name__ == "__main__":
    main()
