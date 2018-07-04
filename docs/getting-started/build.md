# Sample ansible hooks to build with composer  

### build_tasks.yml
```
- name: Init andock-ci environment
  command: "composer install"
  args:
    chdir: "{{ checkout_path }}"
```
