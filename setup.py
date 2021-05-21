from setuptools import setup, find_packages

setup_requires = []

install_requires = [
    'pandas==1.1.5',
    'numpy==1.19.2',
    'pandas_read_xml'
]

dependency_links = [
    'git+https://github.com/nuclearpytherian/MassToMatrix.git',
]

setup(
    name="binpeak",
    version='0.1',
    auther='nuclearpytherian',
    author_email='nuclearpytherian@gmail.com',
    packages=find_packages(),
    install_requires=install_requires,
    setup_requires=setup_requires,
    dependency_links=dependency_links,
)
