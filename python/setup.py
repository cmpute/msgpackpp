import os, shutil
import subprocess
import sys
from pathlib import Path
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
from distutils.sysconfig import get_python_inc, get_config_var

class ZigExtension(Extension):
    def __init__(self, name, package_path):
        super().__init__(name, sources=[])
        self.package_path = package_path

class build_ext_zig(build_ext):
    def build_extension(self, ext):
        if not isinstance(ext, ZigExtension):
            return super().build_extension(ext)

        # get Python include and library path
        python_include = Path(get_python_inc())
        python_libs = Path(get_config_var('installed_base'), 'libs').resolve()
        ext_path = Path(self.get_ext_fullpath(ext.name))
        ext_path.parent.mkdir(parents=True, exist_ok=True)

        # get source file locations
        curdir = Path(__file__).parent.resolve()
        
        # compose build command
        build_cmd = [
            'python', '-m', 'ziglang', 'build',
            f'-DPYTHON_INCLUDE_DIR={python_include}',
            f'-DPYTHON_LIBS_DIR={python_libs}'
        ]
        subprocess.check_call(build_cmd, cwd=ext.package_path)

        out_path = Path(ext.package_path, "zig-out/bin/msgpackpp_python.dll").resolve()
        shutil.copy(out_path, ext_path)


setup(
    name='msgpackpp', # other information is put in pyproject.toml
    ext_modules=[ZigExtension('msgpackpp', './')],
    cmdclass={ 'build_ext': build_ext_zig }
)
