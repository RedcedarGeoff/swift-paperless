// This file was autogenerated by `generate_filterrules.py` from
// https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/b948750d558b58018d1d3393db145d162d44fceb/src-ui/src/app/data/filter-rule-type.ts
// at 2023-07-13 16:09:42.099270
// DO NOT MODIFY BY HAND

import Foundation

enum FilterRuleType: Int, Equatable, CaseIterable {
    enum DataType {
        case boolean
        case correspondent
        case date
        case documentType
        case number
        case storagePath
        case string
        case tag
    }

    case title = 0
    case content = 1
    case asn = 2
    case correspondent = 3
    case storagePath = 25
    case documentType = 4
    case isInInbox = 5
    case hasTagsAll = 6
    case hasTagsAny = 22
    case doesNotHaveTag = 17
    case hasAnyTag = 7
    case createdBefore = 8
    case createdAfter = 9
    case createdYear = 10
    case createdMonth = 11
    case createdDay = 12
    case addedBefore = 13
    case addedAfter = 14
    case modifiedBefore = 15
    case modifiedAfter = 16
    case asnIsnull = 18
    case asnGt = 23
    case asnLt = 24
    case titleContent = 19
    case fulltextQuery = 20
    case fulltextMorelike = 21

    func filterVar() -> String {
        switch self {
        case .title:
            return "title__icontains"
        case .content:
            return "content__icontains"
        case .asn:
            return "archive_serial_number"
        case .correspondent:
            return "correspondent__id"
        case .storagePath:
            return "storage_path__id"
        case .documentType:
            return "document_type__id"
        case .isInInbox:
            return "is_in_inbox"
        case .hasTagsAll:
            return "tags__id__all"
        case .hasTagsAny:
            return "tags__id__in"
        case .doesNotHaveTag:
            return "tags__id__none"
        case .hasAnyTag:
            return "is_tagged"
        case .createdBefore:
            return "created__date__lt"
        case .createdAfter:
            return "created__date__gt"
        case .createdYear:
            return "created__year"
        case .createdMonth:
            return "created__month"
        case .createdDay:
            return "created__day"
        case .addedBefore:
            return "added__date__lt"
        case .addedAfter:
            return "added__date__gt"
        case .modifiedBefore:
            return "modified__date__lt"
        case .modifiedAfter:
            return "modified__date__gt"
        case .asnIsnull:
            return "archive_serial_number__isnull"
        case .asnGt:
            return "archive_serial_number__gt"
        case .asnLt:
            return "archive_serial_number__lt"
        case .titleContent:
            return "title_content"
        case .fulltextQuery:
            return "query"
        case .fulltextMorelike:
            return "more_like_id"
        }
    }

    func dataType() -> DataType {
        switch self {
        case .title:
            return .string
        case .content:
            return .string
        case .asn:
            return .number
        case .correspondent:
            return .correspondent
        case .storagePath:
            return .storagePath
        case .documentType:
            return .documentType
        case .isInInbox:
            return .boolean
        case .hasTagsAll:
            return .tag
        case .hasTagsAny:
            return .tag
        case .doesNotHaveTag:
            return .tag
        case .hasAnyTag:
            return .boolean
        case .createdBefore:
            return .date
        case .createdAfter:
            return .date
        case .createdYear:
            return .number
        case .createdMonth:
            return .number
        case .createdDay:
            return .number
        case .addedBefore:
            return .date
        case .addedAfter:
            return .date
        case .modifiedBefore:
            return .date
        case .modifiedAfter:
            return .date
        case .asnIsnull:
            return .boolean
        case .asnGt:
            return .number
        case .asnLt:
            return .number
        case .titleContent:
            return .string
        case .fulltextQuery:
            return .string
        case .fulltextMorelike:
            return .number
        }
    }

    func defaultValue() -> Bool {
        switch self {
        case .isInInbox:
            return true
        case .hasAnyTag:
            return true

        default:
            return false
        }
    }

    func multiple() -> Bool {
        switch self {
        case .hasTagsAll:
            return true
        case .hasTagsAny:
            return true
        case .doesNotHaveTag:
            return true

        default:
            return false
        }
    }

    static func allMultiples() -> Set<FilterRuleType> {
        return [
            .hasTagsAll,
            .hasTagsAny,
            .doesNotHaveTag,
        ]
    }

    func isNullFilterVar() -> String? {
        switch self {
        case .correspondent:
            return "correspondent__isnull"
        case .storagePath:
            return "storage_path__isnull"
        case .documentType:
            return "document_type__isnull"

        default:
            return nil
        }
    }
}
