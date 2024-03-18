create.project.mssql: check_project_nulity check_app_nulity check_target_existence
	@project_path=$(target)/$(project)_$(app) && \
		cp -r project.tmpl $${project_path} && \
		\
		sed -i'' -e 's/SCHEMATIC__PROJECT_NAME/$(project)/g' $${project_path}/docker/make.env/project.env && \
		sed -i'' -e 's/SCHEMATIC__APP_NAME/$(app)/g' $${project_path}/docker/make.env/project.env && \
		rm -f $${project_path}/docker/make.env/project.env-e && \
		\
		sed -i'' -e 's/SCHEMATIC__DB_TYPE/mssql/g' $${project_path}/docker/make.env/database.env && \
		rm -f $${project_path}/docker/make.env/database.env-e && \
		sed -i'' -e 's/SCHEMATIC__BASE_VERSION/$(shell cat VERSION)/g' $${project_path}/docker/make.env/base_image.env && \
		rm -f $${project_path}/docker/make.env/base_image.env-e && \
		\
		rm -fr $${project_path}/docker/make.env/psql && \
		rm -fr $${project_path}/docker/deploy/psql && \
		\
		sed -i'' -e 's/SCHEMATIC_DB/$(subst -,_,$(project))_$(subst -,_,$(app))/g' $${project_path}/src/databases.yaml && \
		\
		mv $${project_path}/gitignore $${project_path}/.gitignore

create.project.psql: check_project_nulity check_app_nulity check_target_existence
	@project_path=$(target)/$(project)_$(app) && \
		cp -r project.tmpl $${project_path} && \
		\
		sed -i'' -e 's/SCHEMATIC__PROJECT_NAME/$(project)/g' $${project_path}/docker/make.env/project.env && \
		sed -i'' -e 's/SCHEMATIC__APP_NAME/$(app)/g' $${project_path}/docker/make.env/project.env && \
		rm -f $${project_path}/docker/make.env/project.env-e && \
		\
		sed -i'' -e 's/SCHEMATIC__DB_TYPE/psql/g' $${project_path}/docker/make.env/database.env && \
		rm -f $${project_path}/docker/make.env/database.env-e && \
		\
		sed -i'' -e 's/SCHEMATIC__BASE_VERSION/$(shell cat VERSION)/g' $${project_path}/docker/make.env/base_image.env && \
		rm -f $${project_path}/docker/make.env/base_image.env-e && \
		\
		rm -fr $${project_path}/docker/make.env/mssql && \
		rm -fr $${project_path}/docker/deploy/mssql && \
		\
		mv $${project_path}/gitignore $${project_path}/.gitignore

check_project_nulity:
	@[ -z "$(project)" ] && \
		{ echo "Error! Project is NOT specified."; exit 1; } || \
		exit 0

check_app_nulity:
	@[ -z "$(app)" ] && \
		{ echo "Error! App path is NOT specified."; exit 1; } || \
		exit 0

check_target_nulity:
	@[ -z "$(target)" ] && \
		{ echo "Error! Target path is NOT specified."; exit 1; } || \
		exit 0

check_target_existence: check_target_nulity
	@[ -d $(target)/$(project)_$(app) ] && \
		{ echo "Error! Target path already exists: $(target)/$(project)_$(app)"; exit 1; } || \
		exit 0
