import os
import subprocess
import sys
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
from distutils.sysconfig import get_python_inc, get_config_var

class ZigExtension(Extension):
    def __init__(self, name, sources):
        super().__init__(name, sources=[])

class build_zig(build_ext):
    def build_extension(self, ext):
        # 获取 Python 包含路径和库路径
        python_include = get_python_inc()
        python_libs = os.path.abspath(os.path.join(get_config_var('installed_base'), 'libs'))
        build_dir = os.path.abspath(self.build_temp)
        ext_path = self.get_ext_fullpath(ext.name)
        os.makedirs(os.path.dirname(ext_path), exist_ok=True)
        
        # 构建 zig 编译命令
        build_cmd = [
            'python', '-m', 'ziglang',
            'build-lib',
            '-lc', '-dynamic',
            f'-I{python_include}',
            f'-L{python_libs}',
            '-lpython3', 'lib.zig',
            '-femit-bin={}'.format(ext_path),
            '-freference-trace',
        ]
        subprocess.check_call(build_cmd)
        
        # 重命名输出文件（Windows 下生成 .pyd）
        if os.path.exists(ext_path):
            base, ext_name = os.path.splitext(ext_path)
            if ext_name == '.dll':
                os.rename(ext_path, base + '.pyd')

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