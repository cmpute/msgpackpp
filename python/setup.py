import os
import subprocess
import sys
from pathlib import Path
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
from distutils.sysconfig import get_python_inc, get_config_var

class ZigExtension(Extension):
    def __init__(self, name, sources):
        super().__init__(name, sources=[])

class build_zig(build_ext):
    def build_extension(self, ext):
        # get Python include and library path
        python_include = Path(get_python_inc())
        python_libs = Path(get_config_var('installed_base'), 'libs').resolve()
        ext_path = Path(self.get_ext_fullpath(ext.name))
        ext_path.parent.mkdir(parents=True, exist_ok=True)

        # get source file locations
        curdir = Path(__file__).parent.resolve()
        
        # 构建 zig 编译命令
        build_cmd = [
            'python', '-m', 'ziglang', 'build',
            f'-DPYTHON_INCLUDE_DIR={python_include}',
            f'-DPYTHON_LIBS_DIR={python_libs}'
        ]
        subprocess.check_call(build_cmd)

        out_path = "zig-out/bin/msgpackpp_python.dll"
        if os.path.exists(ext_path):
            os.unlink(ext_path)
        os.rename(out_path, ext_path)

# 定义扩展模块
msgpackpp_ext = ZigExtension('msgpackpp', sources=['lib.zig'])

setup(
    name='msgpackpp',
    version='0.1',
    description='A MessagePack extension module',
    ext_modules=[msgpackpp_ext],
    cmdclass={
        'build_ext': build_zig
    }
)