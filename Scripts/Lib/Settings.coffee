class Settings
    @fetch: ( fn ) ->
        chrome.storage.sync.get null, ( sync ) =>
            chrome.storage.local.get null, ( local ) =>
                fn? { sync: sync, local: local }

    @update: ( dict, fn ) ->
        return unless isObject dict
        return if dict?.local? and dict?.sync?

        if dict?.local? and dict?.sync?
            chrome.storage.sync.set dict.sync, () =>
                chrome.storage.local.set dict.local, () =>
                    fn?()
        else if dict?.sync?
            chrome.storage.sync.set dict.sync, () => fn?()
        else if dict?.local?
            chrome.storage.local.set dict.local, () => fn?()

    @clear: ( sync = yes, local = yes, fn ) ->
        return unless sync or local

        if sync and local
            chrome.storage.sync.clear () =>
                chrome.storage.local.clear () =>
                    fn?()
        else if sync
            chrome.storage.sync.clear () => fn?()
        else if local
            chrome.storage.local.clear () => fn?()