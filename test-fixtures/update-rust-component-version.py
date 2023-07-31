import json
import logging
import requests
import re
from github import Github
from pbxproj import XcodeProject

# Constants
GITHUB_REPO = "mozilla/rust-components-swift"
SPM_PACKAGE = "Client.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
FIREFOX_PROJECT = "Client.xcodeproj/project.pbxproj"
RUST_COMPONENTS_ID = "433F87D62788F34500693368"


def _init_logging():
    logging.basicConfig(
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        level=logging.INFO,
    )

# Get the newest version and commit of the Rust components from the GitHub repository
def get_newest_rust_components_version(GITHUB_REPO):
    try:
        repo = Github().get_repo(GITHUB_REPO)
        nightly_tag = repo.get_tags()[0]
        return str(nightly_tag.name), re.findall(r'"([^"]*)"', str(nightly_tag.commit))[0]
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)


# Read the current version and commit of the Rust components from the SPM package file
def read_rust_components_tag_version(SPM_PACKAGE):
    try:
        with open(SPM_PACKAGE) as f:
            data = json.load(f)
            for i in data["pins"]:
                if i["identity"] == "rust-components-swift":
                    return i["state"]["version"], i["state"]["revision"]
    except (FileNotFoundError, json.JSONDecodeError) as e:
        logging.info(f"Error reading rust component tag: {e}")
    except Exception as e:
        logging.info(f"Unexpected error: {e}")
    return None, None


# Read the minimum required version of the Rust components from the Firefox project file
def read_project_min_version(FIREFOX_PROJECT, RUST_COMPONENTS_ID):
    try:
        project = XcodeProject.load(FIREFOX_PROJECT)
        return project.get_object(RUST_COMPONENTS_ID).requirement.version
    except Exception as e:
        logging.info(f"Error reading project minimum version: {e}")
        return None

# Compare version strings to determine if we need to update current version
def compare_versions(current_tag_version, repo_tag_version):
    return current_tag_version < repo_tag_version

# Update the specified file with the new Rust components version and commit
def update_file(current_tag, current_commit, rust_component_repo_tag, rust_component_repo_commit, file_name):
    try:
        with open(file_name, "r+") as file:
            data = file.read()
            for old, new in [(current_tag, rust_component_repo_tag), (current_commit, rust_component_repo_commit)]:
                if old is not None and new is not None:
                    data = data.replace(old, new)
            file.seek(0)
            file.write(data)
    except (FileNotFoundError, IOError) as e:
        logging.info(f"Error updating file: {e}")


def main():
    '''
    STEPS
    1. check Rust Components repo for newest tagged version
    2. compare newest with current SPM and project versions in repo
    3. if same version exit, if not, continue 
    4. update both SMP and project files
    
    '''
    _init_logging()

    rust_component_repo_tag, rust_component_repo_commit = get_newest_rust_components_version(GITHUB_REPO)
    current_tag, current_commit = read_rust_components_tag_version(SPM_PACKAGE)
    current_min_version = read_project_min_version(FIREFOX_PROJECT, RUST_COMPONENTS_ID)

    if current_min_version and compare_versions(current_tag, rust_component_repo_tag):
        update_file(current_tag, current_commit, rust_component_repo_tag, rust_component_repo_commit, SPM_PACKAGE)
        update_file(current_min_version, None, rust_component_repo_tag, None, FIREFOX_PROJECT)

        with open("test-fixtures/newest_tag.txt", "w+") as f:
            f.write(rust_component_repo_tag + "\n")


if __name__ == '__main__':
    main()
