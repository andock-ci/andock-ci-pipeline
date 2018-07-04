# Build your project.  
Why should you build your project first?
The build process is made for a scenario where your production site is hosted on acquia etc.
@TODO

### Sample build_tasks.yml
```
- name: Init andock-ci environment
  command: "composer install"
  args:
    chdir: "{{ checkout_path }}"
```
