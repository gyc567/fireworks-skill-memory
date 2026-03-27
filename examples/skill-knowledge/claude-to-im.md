# claude-to-im / 飞书 API 经验库

> **定位**：claude-to-im skill 及飞书 Open API 的具体经验。使用飞书相关功能时自动加载。
> 最多 30 条，超出时淘汰最旧/最不重要的。最后更新：2026-03-27

## 飞书 Docx API

- 【图片插入】正确流程必须是：① 先插入 `{"block_type": 27, "image": {}}` 空块取得 `block_id`；② 再用该 `block_id` 作为 `parent_node` 调用 `/drive/v1/medias/upload_all`。顺序不能颠倒，否则图片不显示。
- 【index 参数】插入块时 `index` 必须取自 `/blocks/{DOC_ID}`（单块接口）的 `children` 数组长度，而非 `/blocks` 列表接口的总数（列表返回所有嵌套块，数值过大会报 1770001）。
- 【block_type 速查】2=段落 3=H1 4=H2 5=H3 12=bullet 14=代码块 15=引用 22=分割线 27=图片
- 【必填字段】分割线：需加 `"divider": {}`；图片：需加 `"image": {}`；否则 1770001 invalid param。
- 【batch_delete 限制】`end_index` 不能等于文档直接子块总数（只能 < 总数）；文档最后一个非根块无法删除（API bug）。
- 【图片 token 字段】API 返回的 image.token 始终为空字符串，属正常现象，不代表未绑定，需在飞书客户端目视确认。
- 【PATCH 限制】无法通过 PATCH 修改图片块的 token 字段（1770001），图片绑定只能在创建时通过上传流程完成。

## 飞书 Drive API

- 【媒体上传】`/drive/v1/medias/upload_all` 的 `parent_type=docx_image` 时，`parent_node` 必须是图片块的 `block_id`（不是 doc_id），否则上传成功但图片不渲染。
- 【文件权限】`/drive/v1/files/upload_all` 需要 `drive:file:upload` 权限，`medias/upload_all` 用 `docx_image` 类型则不需要额外权限。

## 飞书 Auth

- 【tenant_access_token】通过 `POST /open-apis/auth/v3/tenant_access_token/internal` 获取，参数：`app_id` + `app_secret`，有效期约 2 小时，长任务中途需刷新。
- 【错误码】1770001 = invalid param（字段名/值/index 错误）；99991672 = 权限不足；1061002 = 上传参数错误；1061044 = parent_node 不存在。
