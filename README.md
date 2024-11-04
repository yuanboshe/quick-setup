# quick-setup

> A tool that rapidly generates shell scripts through templates and configurations.

## Overview

Shell script management commonly faces two major issues:
1. Complex structured design and difficult maintenance. Some scripts require parameter changes, feature adjustments, or even logical modifications across different scenarios. This necessitates a structured design where the framework logic is intertwined with script functionality, making them hard to read and maintain.
2. Limited reusability. Each script is typically tailored to specific scenarios, making many features difficult to reuse; the lack of a unified standard makes it challenging to extract and reuse functionalities from one's own or others' scripts.

quick-setup aims to address the aforementioned problems while striving to achieve **low learning cost and quick mastery**.

## Applicable Scenarios

- **Simplifying Script Management**: If you have a multitude of scripts and wish to reduce management complexity, quick-setup offers a set of development standards. Developers only need to follow these standards, break down their scripts into functional templates to form components, and add them to their personal component library, which can then be maintained. When using, quick-setup can combine different components based on configuration files to generate the final automated scripts.
- **Automation and Deployment Scenarios**: If you frequently encounter various automation and deployment scenarios and need to conveniently reuse your own and others' scripts, simply write "menu" configuration files, and quick-setup will generate the final automated scripts. For routine automation tasks, you can maintain a series of "menu" configuration files for different scenarios or directly use configuration files shared by others.
- **Customization of Script Presentation**: For designers who wish to conveniently modify the presentation of scripts without altering their functionality, quick-setup separates the framework from core functions, allowing designers to create different framework templates and easily change the presentation of the final automated scripts.

## Other

For any project-related questions or issues, please submit them to the [issues](https://github.com/yuanboshe/quick-setup/issues).
