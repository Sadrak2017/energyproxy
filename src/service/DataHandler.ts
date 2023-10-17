export class DataHandler {
    private arrayFields: Map<string, number> = new Map();

    countMaxItemsOfArrayFields(jsonData: any, fields: string[]) {
        this.arrayFields = this.buildMapKeyValue(fields)

        this.recursiveGetProperty(jsonData, "", (fieldPath, countItems) => {

            let currentMaxValue = this.arrayFields.get(fieldPath)

            if (currentMaxValue! < countItems) {
                this.arrayFields.set(fieldPath, countItems)
            }
        });
        return this.arrayFields
    }

    private recursiveGetProperty(obj, currentPath, callback) {

        for (let property in obj) {
            if (Array.isArray(obj[property])) {

                let newPath = currentPath.concat("/", property)

                if (this.arrayFields.has(newPath)) {
                    callback(newPath, obj[property].length)
                }

                obj[property].forEach(element => {
                    this.recursiveGetProperty(element, newPath, callback);
                });

            } else if (obj[property] instanceof Object) {
                let newPath = currentPath.concat("/", property)
                this.recursiveGetProperty(obj[property], newPath, callback);
            }
        }
    }

    buildMapKeyValue(fields: string[]): Map<string, number> {
        let values = new Map()
        fields.forEach(field => {
            values.set(field, 0)
        })
        return values;
    }
}
